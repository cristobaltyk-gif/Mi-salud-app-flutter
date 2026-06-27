/// lib/services/ficha_service.dart
///
/// Cliente HTTP para ficha_router.py. El resumen es JSON normal, pero
/// /explicar y /evento/{id} son streams SSE (text/event-stream) — Flutter
/// no tiene fetch con ReadableStream como el navegador, así que usamos
/// http.Client().send() en modo stream y parseamos línea por línea.
///
/// IMPORTANTE: igual que se corrigió en MiSalud web (bug de buffer
/// accumulation en client.js), acá NO asumimos que cada chunk de red
/// trae una línea SSE completa. Se acumula en un buffer y solo se
/// procesan líneas completas terminadas en '\n'.
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/evento_clinico.dart';
import 'storage_service.dart';

class FichaException implements Exception {
  final String mensaje;
  FichaException(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Eventos que puede emitir el stream de explicación.
sealed class ExplicacionEvento {}

class ExplicacionTexto extends ExplicacionEvento {
  final String texto;
  ExplicacionTexto(this.texto);
}

class ExplicacionError extends ExplicacionEvento {
  final String mensaje;
  ExplicacionError(this.mensaje);
}

class ExplicacionDone extends ExplicacionEvento {}

class FichaService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw FichaException('No hay sesión activa');
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// GET /api/ficha/resumen — JSON normal, sin streaming.
  static Future<FichaResumen> obtenerResumen() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.fichaResumenEndpoint),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw FichaException('No se pudo cargar la ficha (${res.statusCode})');
    }

    return FichaResumen.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// GET /api/ficha/explicar — explicación general en lenguaje simple, vía SSE.
  static Stream<ExplicacionEvento> explicarFicha() {
    return _streamSSE(AppConfig.fichaExplicarEndpoint);
  }

  /// GET /api/ficha/evento/{id} — explicación de una consulta puntual, vía SSE.
  static Stream<ExplicacionEvento> explicarEvento(int eventoId) {
    return _streamSSE(AppConfig.fichaEventoExplicarEndpoint(eventoId));
  }

  /// Núcleo común de manejo de Server-Sent Events.
  ///
  /// El backend manda líneas con el prefijo "data: " seguidas de un JSON.
  /// Formatos posibles del JSON, según ficha_router.py:
  ///   {"text": "..."}    → fragmento de texto
  ///   {"error": "..."}   → error de conexión con Claude
  ///   {"done": true}     → fin del stream
  static Stream<ExplicacionEvento> _streamSSE(String url) async* {
    final headers = await _authHeaders();
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield ExplicacionError('Error al conectar (${response.statusCode})');
        return;
      }

      // Buffer de acumulación — un chunk de red puede traer una línea
      // SSE incompleta, o varias líneas de una vez. Nunca asumir 1:1.
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Procesar solo líneas completas (terminadas en \n).
        // La última porción incompleta queda en el buffer para el próximo chunk.
        final partes = buffer.split('\n');
        buffer = partes.removeLast(); // posible línea incompleta, se guarda

        for (final linea in partes) {
          final lineaLimpia = linea.trim();
          if (!lineaLimpia.startsWith('data:')) continue;

          final dataStr = lineaLimpia.substring(5).trim();
          if (dataStr.isEmpty) continue;

          Map<String, dynamic> parsed;
          try {
            parsed = jsonDecode(dataStr) as Map<String, dynamic>;
          } catch (_) {
            continue; // línea no era JSON válido, se ignora (igual que el catch silencioso del backend)
          }

          if (parsed.containsKey('error')) {
            yield ExplicacionError(parsed['error'].toString());
          } else if (parsed.containsKey('done')) {
            yield ExplicacionDone();
          } else if (parsed.containsKey('text')) {
            yield ExplicacionTexto(parsed['text'].toString());
          }
        }
      }
    } finally {
      client.close();
    }
  }
}

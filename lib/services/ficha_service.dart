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
///
/// v1.1: agregado obtenerFichaCuidado() para ver la ficha de un paciente
/// cuidado (GET /api/ficha/cuidado/{rut_paciente}). explicarFicha() y
/// explicarEvento() aceptan ahora un rutPaciente opcional.
///
/// v1.2: agregado descargarPdf() — descarga el PDF (backend de ICA) y
/// lo guarda en un archivo temporal, devolviendo la ruta local. El
/// caller (pantalla) abre el archivo con un visor de PDF.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../models/evento_clinico.dart';
import '../models/ficha_cuidado.dart';
import 'storage_service.dart';

class FichaException implements Exception {
  final String mensaje;
  FichaException(this.mensaje);
  @override
  String toString() => mensaje;
}

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

  static Future<FichaCuidado> obtenerFichaCuidado(String rutPaciente) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.fichaCuidadoEndpoint(rutPaciente)),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw FichaException(_detailDe(res));
    }

    return FichaCuidado.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  static Future<String> descargarPdf(
    int eventoId,
    String tipo, {
    String? rutPaciente,
  }) async {
    final headers = await _authHeaders();
    final url = AppConfig.pdfDescargarEndpoint(eventoId, tipo, rutPaciente: rutPaciente);

    final res = await http.get(Uri.parse(url), headers: headers);

    if (res.statusCode != 200) {
      throw FichaException(_detailDe(res));
    }

    final dir = await getTemporaryDirectory();
    final filename = '${tipo}_$eventoId.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(res.bodyBytes);

    return file.path;
  }

  static String _detailDe(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      return body['detail']?.toString() ?? 'Error inesperado (${r.statusCode})';
    } catch (_) {
      return 'Error inesperado (${r.statusCode})';
    }
  }

  static Stream<ExplicacionEvento> explicarFicha({String? rutPaciente}) {
    final url = rutPaciente != null
        ? '${AppConfig.fichaExplicarEndpoint}?rut_paciente=$rutPaciente'
        : AppConfig.fichaExplicarEndpoint;
    return _streamSSE(url);
  }

  static Stream<ExplicacionEvento> explicarEvento(int eventoId, {String? rutPaciente}) {
    final base = AppConfig.fichaEventoExplicarEndpoint(eventoId);
    final url = rutPaciente != null ? '$base?rut_paciente=$rutPaciente' : base;
    return _streamSSE(url);
  }

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

      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        final partes = buffer.split('\n');
        buffer = partes.removeLast();

        for (final linea in partes) {
          final lineaLimpia = linea.trim();
          if (!lineaLimpia.startsWith('data:')) continue;

          final dataStr = lineaLimpia.substring(5).trim();
          if (dataStr.isEmpty) continue;

          Map<String, dynamic> parsed;
          try {
            parsed = jsonDecode(dataStr) as Map<String, dynamic>;
          } catch (_) {
            continue;
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

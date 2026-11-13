/// lib/services/cotizador_service.dart
///
/// Cliente HTTP para cotizador_router.py (POST /api/cotizador/cotizar).
/// Mismo patron que auth_service.dart: usa el token guardado, y lanza
/// una excepcion con el detail exacto que devuelve el backend cuando
/// algo falla.
library;

import 'dart:convert';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import '../models/cotizacion.dart';
import 'storage_service.dart';

class CotizadorException implements Exception {
  final int statusCode;
  final String mensaje;
  CotizadorException(this.statusCode, this.mensaje);

  @override
  String toString() => mensaje;
}

class CotizadorService {
  /// Solo se cotizan las recetas recientes (no las de hace un año).
  static const int diasRecetasParaCotizar = 3;

  /// fecha 'AAAA-MM-DD' (o ISO) de la atención: ¿es de los últimos 3 días?
  static bool recetaReciente(String fecha) {
    final f = DateTime.tryParse(fecha.length >= 10 ? fecha.substring(0, 10) : fecha);
    if (f == null) return false;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    return !f.isBefore(hoy.subtract(const Duration(days: diasRecetasParaCotizar)));
  }

  static String _detailDe(http.Response r) {
    // El cuerpo se lee como UTF-8 (el servidor no declara la codificación y los
    // acentos llegaban mal). Si no trae "detail" (no lo mandó el Portal sino lo que
    // está delante, p. ej. el servidor reiniciándose), se explica en palabras.
    try {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      final d = body is Map ? body['detail'] : null;
      if (d != null && d.toString().trim().isNotEmpty) return d.toString();
    } catch (_) {}
    if (r.statusCode >= 500) {
      return 'No pudimos conectar con el servidor. Intenta de nuevo en un momento (${r.statusCode}).';
    }
    return 'Error inesperado (${r.statusCode})';
  }

  /// POST /api/cotizador/cotizar
  ///
  /// Cotiza en vivo contra las farmacias disponibles -- puede tardar
  /// varios segundos (varias requests salientes en el backend), no es
  /// instantaneo como los demas endpoints de la app. Requiere sesion
  /// activa (mismo JWT que el resto de la app).
  static Future<CotizacionResultado> cotizarReceta(
    List<ItemReceta> items,
  ) async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw CotizadorException(401, 'No hay sesión activa');
    }

    final res = await http.post(
      Uri.parse(AppConfig.cotizadorCotizarEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items.map((i) => i.toJson()).toList(),
      }),
    );

    if (res.statusCode != 200) {
      throw CotizadorException(res.statusCode, _detailDe(res));
    }

    return CotizacionResultado.fromJson(jsonDecode(res.body));
  }
}

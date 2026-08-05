/// lib/services/cotizador_service.dart
///
/// Cliente HTTP para cotizador_router.py (POST /api/cotizador/cotizar).
/// Mismo patron que auth_service.dart: usa el token guardado, y lanza
/// una excepcion con el detail exacto que devuelve el backend cuando
/// algo falla.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static String _detailDe(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      return body['detail']?.toString() ?? 'Error inesperado (${r.statusCode})';
    } catch (_) {
      return 'Error inesperado (${r.statusCode})';
    }
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

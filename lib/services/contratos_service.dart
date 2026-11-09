/// lib/services/contratos_service.dart
///
/// Términos de uso del Portal: si hay una versión sin aceptar (primera vez o
/// versión nueva publicada desde el Superadmin), se muestra al entrar y no se
/// puede seguir sin aceptarla (misalud-backend /api/contratos).
library;

import 'dart:convert';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ContratoPendiente {
  final String titulo;
  final String texto;
  final int version;
  final String hash;
  const ContratoPendiente(this.titulo, this.texto, this.version, this.hash);
}

class ContratosService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.obtenerToken();
    return {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  /// null si no falta nada (o si no hay red: se vuelve a revisar al próximo ingreso).
  static Future<ContratoPendiente?> pendiente() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.backendBaseUrl}/api/contratos/pendientes'),
          headers: await _headers());
      if (res.statusCode != 200) return null;
      final lista = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['pendientes'] as List<dynamic>? ?? [];
      if (lista.isEmpty) return null;
      final c = lista.first as Map<String, dynamic>;
      return ContratoPendiente(c['titulo'] as String? ?? 'Términos de uso', c['texto'] as String? ?? '',
          (c['version'] as num).toInt(), c['hash'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> aceptar(ContratoPendiente c) async {
    final res = await http.post(Uri.parse('${AppConfig.backendBaseUrl}/api/contratos/aceptar'),
        headers: await _headers(), body: jsonEncode({'version': c.version, 'hash': c.hash}));
    if (res.statusCode != 200) {
      String msg = 'No se pudo registrar';
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d is Map && d['detail'] is String) msg = d['detail'] as String;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

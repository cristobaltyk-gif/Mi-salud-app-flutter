/// lib/services/direccion_service.dart
///
/// Dirección del paciente en Chile, con comuna y verificada en el mapa
/// (igual que la web: components/DireccionChile.jsx).
/// - comunas():   las 346 comunas con su región (backend de ICA, /geo/comunas)
/// - verificar(): ubica calle + número en la comuna elegida (Google) y
///                confirma que quede ahí (/geo/verificar-direccion)
/// - guardar():   la guarda en MiSalud (PUT /api/auth/me/direccion)
/// - tieneComuna(): ¿la dirección guardada termina en una comuna? (las
///                antiguas a veces no la tienen y el domicilio no la ubica)
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class Comuna {
  final String nombre;
  final String region;
  const Comuna(this.nombre, this.region);
}

class DireccionVerificada {
  final bool ok;
  final String mensaje;
  final String direccion;   // "Calle Nº, Depto, Comuna" (lo que se guarda)
  final String encontrada;  // lo que encontró Google
  final String region;
  final double? lat;
  final double? lng;
  const DireccionVerificada({required this.ok, this.mensaje = '', this.direccion = '', this.encontrada = '',
      this.region = '', this.lat, this.lng});
}

class DireccionService {
  static List<Comuna>? _comunas;

  static String normalizar(String t) {
    const con = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sin = 'aeiouunAEIOUUN';
    final b = StringBuffer();
    for (final ch in t.split('')) {
      final i = con.indexOf(ch);
      b.write(i >= 0 ? sin[i] : ch);
    }
    return b.toString().toLowerCase().trim();
  }

  static Future<List<Comuna>> comunas() async {
    if (_comunas != null) return _comunas!;
    final res = await http.get(Uri.parse('${AppConfig.icaBaseUrl}/geo/comunas'));
    if (res.statusCode != 200) throw Exception('No se pudo cargar la lista de comunas');
    final lista = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    _comunas = lista
        .map((c) => Comuna((c as Map<String, dynamic>)['comuna'] as String, c['region'] as String? ?? ''))
        .toList();
    return _comunas!;
  }

  /// ¿La dirección termina en una comuna de Chile? ("…, Curicó")
  static bool tieneComuna(String? direccion, List<Comuna> comunas) {
    final partes = (direccion ?? '').split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (partes.length < 2) return false;
    var ultima = partes.last;
    if (normalizar(ultima) == 'chile' && partes.length > 2) ultima = partes[partes.length - 2];
    final n = normalizar(ultima);
    return comunas.any((c) => normalizar(c.nombre) == n);
  }

  static Future<DireccionVerificada> verificar(
      {required String calle, required String numero, required String comuna, String depto = ''}) async {
    final res = await http.post(
      Uri.parse('${AppConfig.icaBaseUrl}/geo/verificar-direccion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'calle': calle, 'numero': numero, 'comuna': comuna, 'depto': depto}),
    );
    Map<String, dynamic> d = {};
    try {
      d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode != 200) {
      return DireccionVerificada(ok: false,
          mensaje: d['detail'] is String ? d['detail'] as String : 'No se pudo verificar la dirección.');
    }
    return DireccionVerificada(
      ok: d['ok'] == true,
      mensaje: (d['mensaje'] ?? '').toString(),
      direccion: (d['direccion'] ?? '').toString(),
      encontrada: (d['encontrada'] ?? '').toString(),
      region: (d['region'] ?? '').toString(),
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }

  static Future<void> guardar(String direccion) async {
    final token = await StorageService.obtenerToken();
    final res = await http.put(
      Uri.parse('${AppConfig.authBase}/me/direccion'),
      headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
      body: jsonEncode({'direccion': direccion}),
    );
    if (res.statusCode != 200) {
      String msg = 'No se pudo guardar la dirección';
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d is Map && d['detail'] is String) msg = d['detail'] as String;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

/// lib/services/cuidador_service.dart
///
/// Cliente HTTP para cuidador_router.py.
library;

import 'dart:convert';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import '../models/cuidador.dart';
import 'storage_service.dart';

class CuidadorException implements Exception {
  final String mensaje;
  CuidadorException(this.mensaje);
  @override
  String toString() => mensaje;
}

class CuidadorService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw CuidadorException('No hay sesión activa');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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

  /// GET /api/cuidador/niveles-acceso — catálogo para el selector de la UI.
  static Future<List<NivelAcceso>> nivelesAcceso() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.cuidadorNivelesAccesoEndpoint),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final niveles = body['niveles'] as List<dynamic>;
    return niveles.map((n) => NivelAcceso.fromJson(n as Map<String, dynamic>)).toList();
  }

  /// POST /api/cuidador/invitar — el paciente genera un QR para un cuidador.
  static Future<InvitacionGenerada> invitar({
    required String cuidadorNombre,
    required String cuidadorApellidos,
    required String cuidadorRut,
    required String nivelAcceso,
    String? relacion,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse(AppConfig.cuidadorInvitarEndpoint),
      headers: headers,
      body: jsonEncode({
        'cuidador_nombre': cuidadorNombre,
        'cuidador_apellidos': cuidadorApellidos,
        'cuidador_rut': cuidadorRut,
        'nivel_acceso': nivelAcceso,
        if (relacion != null) 'relacion': relacion,
      }),
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
    return InvitacionGenerada.fromJson(jsonDecode(res.body));
  }

  /// GET /api/cuidador/mis-invitaciones — invitaciones creadas por el paciente.
  static Future<List<InvitacionCuidador>> misInvitaciones() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.cuidadorMisInvitacionesEndpoint),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final lista = body['invitaciones'] as List<dynamic>;
    return lista.map((i) => InvitacionCuidador.fromJson(i as Map<String, dynamic>)).toList();
  }

  /// DELETE /api/cuidador/invitar/{id} — revoca invitación PENDIENTE.
  static Future<void> revocarInvitacion(int invitacionId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse(AppConfig.cuidadorRevocarInvitacionEndpoint(invitacionId)),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
  }

  /// DELETE /api/cuidador/vinculo/{id} — revoca vínculo YA CONFIRMADO.
  static Future<void> revocarVinculo(int vinculoId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse(AppConfig.cuidadorRevocarVinculoEndpoint(vinculoId)),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
  }

  /// POST /api/cuidador/escanear — el cuidador confirma el vínculo con su
  /// propia sesión iniciada (el RUT de sesión debe calzar con el declarado).
  static Future<void> escanearQR(String token) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse(AppConfig.cuidadorEscanearEndpoint),
      headers: headers,
      body: jsonEncode({'token': token}),
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
  }

  /// v2: invitaciones pendientes a mi RUT (quién me invita y qué podré ver).
  static Future<List<Map<String, dynamic>>> invitacionesRecibidas() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse(AppConfig.cuidadorRecibidasEndpoint), headers: headers);
    if (res.statusCode != 200) throw CuidadorException(_detailDe(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['invitaciones'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  /// v2: aceptar o rechazar una invitación desde la propia cuenta.
  static Future<void> responder(int invitacionId, {required bool aceptar}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse(AppConfig.cuidadorResponderEndpoint(invitacionId, aceptar)),
        headers: headers);
    if (res.statusCode != 200) throw CuidadorException(_detailDe(res));
  }

  /// v2: QR en persona → la invitación (no vincula todavía; luego responder()).
  static Future<Map<String, dynamic>> verQR(String token) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse(AppConfig.cuidadorVerQREndpoint),
        headers: headers, body: jsonEncode({'token': token}));
    if (res.statusCode != 200) throw CuidadorException(_detailDe(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['invitacion'] as Map<String, dynamic>;
  }

  /// GET /api/cuidador/mis-cuidados — pacientes que este usuario cuida.
  static Future<List<PacienteCuidado>> misCuidados() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.cuidadorMisCuidadosEndpoint),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw CuidadorException(_detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final lista = body['pacientes'] as List<dynamic>;
    return lista.map((p) => PacienteCuidado.fromJson(p as Map<String, dynamic>)).toList();
  }
}

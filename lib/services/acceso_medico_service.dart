/// lib/services/acceso_medico_service.dart
///
/// Cliente HTTP para ficha_compartida_router.py (prefix /api/compartir).
/// Cada función acepta un `rutPaciente` opcional: si se pasa, el backend
/// valida que la sesión actual tenga un vínculo confirmado con
/// nivel_acceso="completo" hacia ese RUT antes de operar.
library;

import 'dart:convert';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import '../models/acceso_medico.dart';
import 'storage_service.dart';

class AccesoMedicoException implements Exception {
  final String mensaje;
  AccesoMedicoException(this.mensaje);
  @override
  String toString() => mensaje;
}

class AccesoMedicoService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw AccesoMedicoException('No hay sesión activa');
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

  /// POST /api/compartir/generar
  static Future<LinkGenerado> generarLink({String? rutPaciente}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse(AppConfig.compartirGenerarEndpoint),
      headers: headers,
      body: jsonEncode({
        if (rutPaciente != null) 'rut_paciente': rutPaciente,
      }),
    );
    if (res.statusCode != 200) {
      throw AccesoMedicoException(_detailDe(res));
    }
    return LinkGenerado.fromJson(jsonDecode(res.body));
  }

  /// GET /api/compartir/mis-links
  static Future<List<AccesoMedico>> misLinks({String? rutPaciente}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(AppConfig.compartirMisLinksEndpoint).replace(
      queryParameters: rutPaciente != null ? {'rut_paciente': rutPaciente} : null,
    );
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      throw AccesoMedicoException(_detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final lista = body['links'] as List<dynamic>;
    return lista.map((l) => AccesoMedico.fromJson(l as Map<String, dynamic>)).toList();
  }

  /// DELETE /api/compartir/{id}
  static Future<void> revocarLink(int id, {String? rutPaciente}) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse(AppConfig.compartirRevocarEndpoint(id)),
      headers: headers,
      body: rutPaciente != null ? jsonEncode({'rut_paciente': rutPaciente}) : null,
    );
    if (res.statusCode != 200) {
      throw AccesoMedicoException(_detailDe(res));
    }
  }

  /// POST /api/compartir/enviar
  static Future<void> enviarPorEmail(String emailMedico, {String? rutPaciente}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse(AppConfig.compartirEnviarEndpoint),
      headers: headers,
      body: jsonEncode({
        'email_medico': emailMedico,
        if (rutPaciente != null) 'rut_paciente': rutPaciente,
      }),
    );
    if (res.statusCode != 200) {
      throw AccesoMedicoException(_detailDe(res));
    }
  }

  /// GET /api/rnpi/perfil-publico/{rut} — sin auth, dato público RNPI.
  /// Devuelve null si el médico no está en medicos_misalud (ej. médico
  /// ICA normal, no RNPI) — no bloquea la pantalla si falla.
  static Future<Map<String, dynamic>?> obtenerPerfilMedico(String rut) async {
    try {
      final res = await http.get(Uri.parse(AppConfig.rnpiPerfilPublicoEndpoint(rut)));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

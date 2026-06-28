/// lib/services/acceso_medico_service.dart
///
/// Cliente HTTP para ficha_compartida_router.py (prefix /api/compartir).
/// Cada función acepta un `rutPaciente` opcional: si se pasa, el backend
/// valida que la sesión actual tenga un vínculo confirmado con
/// nivel_acceso="completo" hacia ese RUT antes de operar.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
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
    try {
      final body = jsonDecode(r.body);
      return body['detail']?.toString() ?? 'Error inesperado (${r.statusCode})';
    } catch (_) {
      return 'Error inesperado (${r.statusCode})';
    }
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
}

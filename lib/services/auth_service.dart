/// lib/services/auth_service.dart — v2.0
///
/// Cliente HTTP para auth_router.py.
///
/// v2.0 (alineado con misalud-backend ya corregido — auditoría CRÍTICO-2):
/// /api/auth/buscar y /api/auth/activar cambiaron de contrato. Antes
/// /buscar devolvía {existe, ya_activado, nombre, email} — exponía datos
/// personales de cualquier paciente sin autenticación, dado solo su RUT.
/// Ahora /buscar solo dispara (si corresponde) el envío de un link de
/// activación de un solo uso al correo ya registrado, y responde siempre
/// el mismo mensaje genérico, exista o no el RUT.
///
/// /api/auth/activar ya no existe — se reemplaza por dos pasos, ambos
/// completados en el NAVEGADOR (la app no maneja deep linking del
/// token — no hay signing de producción ni publicación en tiendas aún,
/// se evalúa a futuro): el paciente pide el link desde la app
/// (buscarRut), y completa la activación en el link del correo, en el
/// navegador del teléfono. Después vuelve a la app y hace login normal.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/paciente.dart';
import 'storage_service.dart';

/// Excepción con el mensaje exacto que viene del backend (`detail` de FastAPI).
class AuthException implements Exception {
  final int statusCode;
  final String mensaje;
  AuthException(this.statusCode, this.mensaje);

  @override
  String toString() => mensaje;
}

class AuthService {
  static Map<String, String> get _headersJson => {
        'Content-Type': 'application/json',
      };

  static String _detailDe(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      return body['detail']?.toString() ?? 'Error inesperado (${r.statusCode})';
    } catch (_) {
      return 'Error inesperado (${r.statusCode})';
    }
  }

  /// POST /api/auth/buscar — dispara (si corresponde) el correo de
  /// activación. Respuesta siempre genérica, sin importar si el RUT
  /// existe o no — no se puede usar para enumerar pacientes.
  /// Devuelve el mensaje del backend para mostrarlo tal cual en la UI.
  static Future<String> buscarRut(String rut) async {
    final res = await http.post(
      Uri.parse(AppConfig.buscarRutEndpoint),
      headers: _headersJson,
      body: jsonEncode({'rut': rut}),
    );
    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['mensaje'] ??
        'Si el RUT corresponde a una ficha registrada, se enviarán instrucciones al correo asociado.';
  }

  /// POST /api/auth/login
  /// Lanza AuthException con el detalle exacto:
  ///   404 → "RUT no registrado"
  ///   401 → "Cuenta no activada" | "Contraseña incorrecta"
  static Future<Paciente> login(String rut, String password) async {
    final res = await http.post(
      Uri.parse(AppConfig.loginEndpoint),
      headers: _headersJson,
      body: jsonEncode({'rut': rut, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await StorageService.guardarSesion(
      token: body['token'],
      rut: body['rut'],
      nombre: body['nombre'] ?? '',
    );
    return Paciente.fromLogin(body);
  }

  /// GET /api/auth/me — requiere token guardado.
  static Future<Paciente> me() async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw AuthException(401, 'No hay sesión activa');
    }

    final res = await http.get(
      Uri.parse(AppConfig.meEndpoint),
      headers: {..._headersJson, 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }

    return Paciente.fromMe(jsonDecode(res.body));
  }

  static Future<void> logout() async {
    await StorageService.cerrarSesion();
  }
}

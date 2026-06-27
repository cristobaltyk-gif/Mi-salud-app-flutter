/// lib/services/auth_service.dart
///
/// Cliente HTTP para auth_router.py. Replica exactamente los códigos de
/// error que usa el backend para que la UI pueda mostrar el mensaje
/// correcto en cada caso (RUT no registrado vs cuenta no activada vs
/// contraseña incorrecta — login.py v1.5 los distingue a propósito).
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

class ResultadoBuscarRut {
  final bool existe;
  final bool yaActivado;
  final String? nombre;
  final String? email;

  ResultadoBuscarRut({
    required this.existe,
    this.yaActivado = false,
    this.nombre,
    this.email,
  });

  factory ResultadoBuscarRut.fromJson(Map<String, dynamic> json) {
    return ResultadoBuscarRut(
      existe: json['existe'] ?? false,
      yaActivado: json['ya_activado'] ?? false,
      nombre: json['nombre'],
      email: json['email'],
    );
  }
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

  /// POST /api/auth/buscar — consulta si el RUT existe y si ya activó cuenta.
  static Future<ResultadoBuscarRut> buscarRut(String rut) async {
    final res = await http.post(
      Uri.parse(AppConfig.buscarRutEndpoint),
      headers: _headersJson,
      body: jsonEncode({'rut': rut}),
    );
    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }
    return ResultadoBuscarRut.fromJson(jsonDecode(res.body));
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

  /// POST /api/auth/activar — primera vez que el paciente crea su clave.
  static Future<Paciente> activarCuenta({
    required String rut,
    required String email,
    required String nuevaPassword,
  }) async {
    final res = await http.post(
      Uri.parse(AppConfig.activarCuentaEndpoint),
      headers: _headersJson,
      body: jsonEncode({
        'rut': rut,
        'email': email,
        'nueva_password': nuevaPassword,
      }),
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

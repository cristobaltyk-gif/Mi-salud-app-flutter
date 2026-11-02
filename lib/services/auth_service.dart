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
///
/// v2.1 (huella y código al correo, auth_router v2.4):
/// - login() manda la llave del teléfono (si es de confianza entra directo).
///   Si el teléfono es nuevo, el backend manda un código de 6 dígitos al
///   correo: login() devuelve ResultadoLogin con `desafio` y se completa con
///   loginCodigo(). Al completar, el teléfono queda de confianza (llave).
/// - renovar(): después de la huella, sesión nueva con la llave (sin contraseña).
/// - cerrarSesionServidor(): al tocar "Salir", anula la sesión y la llave.
library;

import 'dart:io' show Platform;

import 'dart:convert';
import 'http_sesion.dart' as http;
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

/// Resultado del login: o ya hay sesión (paciente), o falta el código del correo.
class ResultadoLogin {
  final Paciente? paciente;
  final String? desafio;
  final String? email;
  ResultadoLogin({this.paciente, this.desafio, this.email});
  bool get requiereCodigo => desafio != null;
}

class AuthService {
  static Map<String, String> get _dispositivo => {
        'tipo': 'app',
        'nombre_dispositivo': Platform.isAndroid ? 'Teléfono Android' : (Platform.isIOS ? 'iPhone' : 'Teléfono'),
      };

  static Future<Paciente> _guardar(Map<String, dynamic> body) async {
    await StorageService.guardarSesion(
      token: body['token'],
      rut: body['rut'],
      nombre: body['nombre'] ?? '',
    );
    await StorageService.guardarLlave(body['llave_dispositivo'] as String?);
    return Paciente.fromLogin(body);
  }

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
  static Future<ResultadoLogin> login(String rut, String password) async {
    final res = await http.post(
      Uri.parse(AppConfig.loginEndpoint),
      headers: _headersJson,
      body: jsonEncode({
        'rut': rut,
        'password': password,
        'soporta_codigo': true,
        'llave_dispositivo': await StorageService.obtenerLlave(),
        ..._dispositivo,
      }),
    );

    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['requiere_codigo'] == true) {
      return ResultadoLogin(desafio: body['desafio'] as String?, email: body['email'] as String?);
    }
    return ResultadoLogin(paciente: await _guardar(body));
  }

  /// POST /api/auth/login/codigo — código de 6 dígitos del correo (teléfono nuevo).
  static Future<Paciente> loginCodigo(String desafio, String codigo) async {
    final res = await http.post(
      Uri.parse(AppConfig.loginCodigoEndpoint),
      headers: _headersJson,
      body: jsonEncode({'desafio': desafio, 'codigo': codigo, ..._dispositivo}),
    );
    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }
    return _guardar(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// POST /api/auth/renovar — después de la huella: sesión nueva sin contraseña.
  /// Lanza AuthException(403) si el teléfono ya no está vinculado.
  static Future<void> renovar() async {
    final llave = await StorageService.obtenerLlave();
    if (llave == null || llave.isEmpty) {
      throw AuthException(403, 'Este teléfono no está vinculado');
    }
    final res = await http.post(
      Uri.parse(AppConfig.renovarEndpoint),
      headers: _headersJson,
      body: jsonEncode({'llave_dispositivo': llave}),
    );
    if (res.statusCode != 200) {
      if (res.statusCode == 403) {
        // Llave anulada (salió, cambió la contraseña o la quitó): vuelve la contraseña
        await StorageService.guardarBiometria(false);
      }
      throw AuthException(res.statusCode, _detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await StorageService.guardarSesion(token: body['token'], rut: body['rut'], nombre: body['nombre'] ?? '');
  }

  /// POST /api/auth/dispositivos/vincular — con sesión y la contraseña confirmada,
  /// este teléfono queda de confianza (para activar la huella sin salir).
  static Future<void> vincularTelefono(String password) async {
    final token = await StorageService.obtenerToken();
    final res = await http.post(
      Uri.parse(AppConfig.vincularEndpoint),
      headers: {..._headersJson, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'password': password, ..._dispositivo}),
    );
    if (res.statusCode != 200) {
      throw AuthException(res.statusCode, _detailDe(res));
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await StorageService.guardarLlave(body['llave_dispositivo'] as String?);
  }

  /// "Salir": anula la sesión y la llave del teléfono en el backend (si falla, igual se sale).
  static Future<void> cerrarSesionServidor() async {
    try {
      final token = await StorageService.obtenerToken();
      if (token == null || token.isEmpty) return;
      await http.post(
        Uri.parse(AppConfig.logoutEndpoint),
        headers: {..._headersJson, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'llave_dispositivo': await StorageService.obtenerLlave()}),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {
      // sin conexión: se sale igual
    }
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

/// lib/services/storage_service.dart
///
/// Persistencia local simple vía shared_preferences. Guarda el JWT y
/// datos mínimos del paciente para no tener que loguear cada vez que
/// se abre la app.
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StorageService {
  static Future<void> guardarSesion({
    required String token,
    required String rut,
    required String nombre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsJwtKey, token);
    await prefs.setString(AppConfig.prefsRutKey, rut);
    await prefs.setString(AppConfig.prefsNombreKey, nombre);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.prefsJwtKey);
  }

  static Future<String?> obtenerRut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.prefsRutKey);
  }

  static Future<String?> obtenerNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.prefsNombreKey);
  }

  static Future<bool> haySesionGuardada() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefsJwtKey);
    await prefs.remove(AppConfig.prefsRutKey);
    await prefs.remove(AppConfig.prefsNombreKey);
  }
}

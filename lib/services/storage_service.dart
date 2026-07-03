/// lib/services/storage_service.dart
///
/// Persistencia local simple vía shared_preferences. Guarda el JWT y
/// datos mínimos del paciente para no tener que loguear cada vez que
/// se abre la app.
///
/// v1.1: agrega guardarRecordatorios / obtenerRecordatorios para
/// persistir los horarios de alarma localmente al hacer login —
/// así AlarmService puede reprogramar las alarmas sin necesitar
/// token válido ni conexión al backend.
library;

import 'dart:convert';
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
    await prefs.remove(AppConfig.prefsRecordatoriosKey);
  }

  /// Guarda la lista de recordatorios como JSON al hacer login o
  /// al sincronizar. AlarmService los lee desde aquí para programar
  /// alarmas locales sin necesitar token ni conexión.
  static Future<void> guardarRecordatorios(List<Map<String, dynamic>> recordatorios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsRecordatoriosKey, jsonEncode(recordatorios));
  }

  /// Retorna los recordatorios guardados localmente, o lista vacía si
  /// nunca se han guardado (primer uso, o sesión limpia).
  static Future<List<Map<String, dynamic>>> obtenerRecordatorios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConfig.prefsRecordatoriosKey);
    if (raw == null) return [];
    final lista = jsonDecode(raw) as List<dynamic>;
    return lista.map((e) => e as Map<String, dynamic>).toList();
  }
}

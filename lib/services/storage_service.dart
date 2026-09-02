/// lib/services/storage_service.dart — v2.0
///
/// v1.1: agrega guardarRecordatorios / obtenerRecordatorios para
/// persistir los horarios de alarma localmente al hacer login —
/// así AlarmService puede reprogramar las alarmas sin necesitar
/// token válido ni conexión al backend.
///
/// v2.0 (auditoría — almacenamiento sensible sin cifrar): antes todo
/// esto vivía en shared_preferences, que en Android guarda un XML
/// plano dentro del sandbox de la app (legible sin cifrado en un
/// dispositivo rooteado o con acceso físico/backup) y en iOS un
/// plist igual de plano. Se migra a flutter_secure_storage (Keystore
/// en Android, Keychain en iOS — cifrado por el sistema operativo) el
/// token de sesión, el RUT y los recordatorios (contienen nombres de
/// medicamentos — dato de salud sensible bajo Ley 21.719). El nombre
/// del paciente se mantiene en shared_preferences por ser el único
/// dato no sensible de por sí.
///
/// Requiere agregar flutter_secure_storage a pubspec.yaml.
library;

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StorageService {
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> guardarSesion({
    required String token,
    required String rut,
    required String nombre,
  }) async {
    await _secure.write(key: AppConfig.prefsJwtKey, value: token);
    await _secure.write(key: AppConfig.prefsRutKey, value: rut);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsNombreKey, nombre);
  }

  static Future<String?> obtenerToken() {
    return _secure.read(key: AppConfig.prefsJwtKey);
  }

  static Future<String?> obtenerRut() {
    return _secure.read(key: AppConfig.prefsRutKey);
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
    await _secure.delete(key: AppConfig.prefsJwtKey);
    await _secure.delete(key: AppConfig.prefsRutKey);
    await _secure.delete(key: AppConfig.prefsRecordatoriosKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefsNombreKey);
  }

  /// Guarda la lista de recordatorios como JSON al hacer login o
  /// al sincronizar. AlarmService los lee desde aquí para programar
  /// alarmas locales sin necesitar token ni conexión.
  static Future<void> guardarRecordatorios(List<Map<String, dynamic>> recordatorios) async {
    await _secure.write(
      key: AppConfig.prefsRecordatoriosKey,
      value: jsonEncode(recordatorios),
    );
  }

  /// Retorna los recordatorios guardados localmente, o lista vacía si
  /// nunca se han guardado (primer uso, o sesión limpia).
  static Future<List<Map<String, dynamic>>> obtenerRecordatorios() async {
    final raw = await _secure.read(key: AppConfig.prefsRecordatoriosKey);
    if (raw == null) return [];
    final lista = jsonDecode(raw) as List<dynamic>;
    return lista.map((e) => e as Map<String, dynamic>).toList();
  }
}

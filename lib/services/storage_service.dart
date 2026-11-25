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
import '../i18n/idioma.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Modo sin red (sesión vencida y sin internet): el RUT sale de la ficha
  /// guardada en el teléfono para que el inicio funcione igual.
  static Future<void> guardarRut(String rut) =>
      _secure.write(key: AppConfig.prefsRutKey, value: rut);

  static Future<bool> haySesionGuardada() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  // ── Teléfono de confianza: llave del dispositivo y huella ──
  static Future<void> guardarLlave(String? llave) async {
    if (llave == null || llave.isEmpty) return;
    // Llave distinta (otra cuenta en este teléfono, o la anterior se anuló):
    // la huella de antes ya no corresponde — se vuelve a ofrecer.
    final anterior = await obtenerLlave();
    if (anterior != null && anterior.isNotEmpty && anterior != llave) {
      await _secure.delete(key: AppConfig.prefsBiometriaKey);
    }
    await _secure.write(key: AppConfig.prefsLlaveKey, value: llave);
  }

  static Future<String?> obtenerLlave() => _secure.read(key: AppConfig.prefsLlaveKey);

  /// null: aún no se le preguntó · true: entra con huella · false: no quiso
  static Future<bool?> biometriaActiva() async {
    final v = await _secure.read(key: AppConfig.prefsBiometriaKey);
    return v == null ? null : v == 'si';
  }

  static Future<void> guardarBiometria(bool activa) =>
      _secure.write(key: AppConfig.prefsBiometriaKey, value: activa ? 'si' : 'no');

  /// Huella activa y llave guardada: puede renovar la sesión sin contraseña.
  static Future<bool> puedeUsarHuella() async =>
      (await biometriaActiva() ?? false) && ((await obtenerLlave()) ?? '').isNotEmpty;

  /// Sesión vencida (no la cerró el paciente): se borra el token y el RUT,
  /// pero NO los recordatorios — las alarmas de medicamentos siguen sonando.
  static Future<void> cerrarSesionVencida() async {
    await _secure.delete(key: AppConfig.prefsJwtKey);
    await _secure.delete(key: AppConfig.prefsRutKey);
  }

  /// "Salir" (v2): como un banco, el teléfono sigue de confianza — se
  /// conservan la llave, la huella, el nombre ("Hola, …") y los recordatorios
  /// (las alarmas siguen sonando). Solo se borra la sesión.
  /// olvidar=true ("Olvidar este teléfono"): se borra todo.
  static Future<void> cerrarSesion({bool olvidar = false}) async {
    await _secure.delete(key: AppConfig.prefsJwtKey);
    await _secure.delete(key: AppConfig.prefsRutKey);
    if (!olvidar) return;
    await _secure.delete(key: AppConfig.prefsRecordatoriosKey);
    await _secure.delete(key: AppConfig.prefsLlaveKey);
    await _secure.delete(key: AppConfig.prefsBiometriaKey);
    await _secure.delete(key: 'misalud_mis_cuidados');
    await borrarCopia(); // sin su llave la copia cifrada no sirve; el archivo también se borra

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefsNombreKey);
    await Idioma.olvidar(); // al volver a abrir se pregunta el idioma
  }

  // ── Copia cifrada de la ficha (lectura sin internet) ──
  // El archivo cifrado vive en el sandbox de la app; su llave, en el
  // almacenamiento seguro (Keystore/Keychain). Una sin la otra no sirve.
  // `rut` vacío/null = la ficha propia; con rut = una persona que el usuario cuida.
  static String _llaveCopiaKey(String? rut) =>
      (rut == null || rut.isEmpty) ? AppConfig.prefsCopiaLlaveKey : '${AppConfig.prefsCopiaLlaveKey}_$rut';

  static Future<void> guardarLlaveCopia(String llaveBase64, {String? rut}) =>
      _secure.write(key: _llaveCopiaKey(rut), value: llaveBase64);

  static Future<String?> obtenerLlaveCopia({String? rut}) => _secure.read(key: _llaveCopiaKey(rut));

  static Future<File> archivoCopia({String? rut}) async {
    final dir = await getApplicationSupportDirectory();
    final nombre = (rut == null || rut.isEmpty)
        ? AppConfig.copiaArchivoNombre
        : 'copia_cuidado_${rut.replaceAll(RegExp(r'[^0-9kK]'), '')}.enc';
    return File('${dir.path}/$nombre');
  }

  /// Borra de este teléfono la copia de una persona cuidada (vínculo revocado).
  static Future<void> borrarCopiaCuidado(String rut) async {
    await _secure.delete(key: _llaveCopiaKey(rut));
    final archivo = await archivoCopia(rut: rut);
    if (await archivo.exists()) await archivo.delete();
  }

  /// Borra TODAS las copias cifradas (la propia y las de personas cuidadas) y
  /// sus llaves. Las notas sin conexión aún no enviadas NO se borran: son
  /// registros clínicos y se envían en el próximo ingreso con red.
  static Future<void> borrarCopia() async {
    final todas = await _secure.readAll();
    for (final k in todas.keys) {
      if (k == AppConfig.prefsCopiaLlaveKey || k.startsWith('${AppConfig.prefsCopiaLlaveKey}_')) {
        await _secure.delete(key: k);
      }
    }
    final dir = await getApplicationSupportDirectory();
    if (await dir.exists()) {
      await for (final f in dir.list()) {
        final nombre = f.uri.pathSegments.isEmpty ? '' : f.uri.pathSegments.last;
        if (f is File && (nombre == AppConfig.copiaArchivoNombre || nombre.startsWith('copia_cuidado_'))) {
          await f.delete();
        }
      }
    }
  }

  // ── Lista de personas que el usuario cuida (para usarla sin internet) ──
  static Future<void> guardarMisCuidados(String json) =>
      _secure.write(key: 'misalud_mis_cuidados', value: json);

  static Future<String?> obtenerMisCuidados() => _secure.read(key: 'misalud_mis_cuidados');

  // ── Notas de consultas sin conexión (cifradas en Keystore/Keychain) ──
  static Future<List<Map<String, dynamic>>> obtenerNotasOffline() async {
    final raw = await _secure.read(key: AppConfig.prefsNotasOfflineKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> guardarNotasOffline(List<Map<String, dynamic>> notas) =>
      _secure.write(key: AppConfig.prefsNotasOfflineKey, value: jsonEncode(notas));

  static Future<List<Map<String, dynamic>>> obtenerAccesosOffline() async {
    final raw = await _secure.read(key: AppConfig.prefsAccesosOfflineKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> guardarAccesosOffline(List<Map<String, dynamic>> accesos) =>
      _secure.write(key: AppConfig.prefsAccesosOfflineKey, value: jsonEncode(accesos));

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

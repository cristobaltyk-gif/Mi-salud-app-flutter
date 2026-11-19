/// lib/services/notas_offline_service.dart — v1.0
///
/// Notas que un profesional escribe durante una CONSULTA SIN CONEXIÓN
/// (ver consulta_sin_conexion_service.dart).
///
/// - guardar(): la nota se sella en el teléfono (SHA-256 de todos sus campos,
///   en orden fijo) y queda pendiente en el almacenamiento seguro
///   (Keystore/Keychain, cifrado). Nadie puede cambiarla después: si el texto
///   cambia, el sello deja de coincidir y la Ficha la rechaza.
/// - enviarPendientes(): con red, las manda a MiSalud (/api/copia/notas-offline),
///   que las pasa a la Ficha. Profesional verificado en el RNPI → atención
///   normal en la ficha; si no → queda para revisión del superadmin.
///   Se llama sola al abrir la ficha con internet, ANTES de pedirla (así la
///   ficha que se muestra ya trae la nota); sin red no hace nada.
///
/// El sello debe calcularse EXACTAMENTE igual que en
/// Ficha-cl-nica-backend/modules/notas_offline/router.py (calcular_sello):
/// cada campo como "<largo en bytes UTF-8>:<texto>", concatenados.
library;

import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class NotasOfflineService {
  static const String _formatoSello = '1';
  /// Mismo orden que CAMPOS en la Ficha (modules/notas_offline/router.py).
  /// "medicamentos" es la receta estructurada como texto JSON.
  static const List<String> campos = [
    'atencion', 'diagnostico', 'indicaciones', 'receta', 'examenes',
    'orden_kinesiologia', 'indicacion_quirurgica', 'medicamentos',
  ];
  static bool _enviando = false;

  static String _idLocal() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<String> calcularSello(Map<String, dynamic> n) async {
    final contenido = (n['contenido'] as Map?) ?? {};
    final partes = <String>[
      _formatoSello,
      n['id_local'] as String,
      n['rut_paciente'] as String,
      n['medico_rut'] as String,
      n['medico_nombre'] as String,
      n['escrita_at'] as String,
      (n['aceptada_at'] as String?) ?? '',
      for (final c in campos) (contenido[c] as String?) ?? '',
    ];
    final texto = partes.map((p) => '${utf8.encode(p).length}:$p').join();
    final hash = await Sha256().hash(utf8.encode(texto));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Sella y guarda una nota pendiente. Devuelve el id local.
  static Future<String> guardar({
    required String rutPaciente,
    required String medicoRut,
    required String medicoNombre,
    required DateTime aceptadaAt,
    required Map<String, String> contenido,
  }) async {
    final nota = <String, dynamic>{
      'id_local': _idLocal(),
      'rut_paciente': rutPaciente,
      'medico_rut': medicoRut.trim(),
      'medico_nombre': medicoNombre.trim(),
      'escrita_at': DateTime.now().toUtc().toIso8601String(),
      'aceptada_at': aceptadaAt.toUtc().toIso8601String(),
      'contenido': {for (final c in campos) c: c == 'medicamentos' ? (contenido[c] ?? '[]') : (contenido[c] ?? '').trim()},
    };
    nota['sello'] = await calcularSello(nota);
    final notas = await StorageService.obtenerNotasOffline();
    notas.add(nota);
    await StorageService.guardarNotasOffline(notas);
    return nota['id_local'] as String;
  }

  static Future<int> cantidadPendientes() async => (await StorageService.obtenerNotasOffline()).length;

  // ── Accesos sin conexión ─────────────────────────────────────────────────
  // Cada profesional que abre la ficha queda registrado (haya escrito nota o
  // no). Al volver la red se envía: verificado en el RNPI → aparece en el
  // historial de accesos igual que un acceso con red; si no → superadmin.
  // Sello igual que calcular_sello_acceso() en la Ficha.

  static Future<String> _selloAcceso(Map<String, dynamic> a) async {
    final partes = <String>[
      'acceso-1', a['id_local'] as String, a['rut_paciente'] as String, a['medico_rut'] as String,
      a['medico_nombre'] as String, a['inicio'] as String, a['fin'] as String,
    ];
    final texto = partes.map((p) => '${utf8.encode(p).length}:$p').join();
    final hash = await Sha256().hash(utf8.encode(texto));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Registra que un profesional abrió la ficha. `fin` = hasta cuándo puede
  /// durar la sesión; se ajusta con cerrarAcceso() al terminar.
  static Future<String> registrarAcceso({
    required String rutPaciente,
    required String medicoRut,
    required String medicoNombre,
    required DateTime fin,
  }) async {
    final a = <String, dynamic>{
      'id_local': _idLocal(),
      'rut_paciente': rutPaciente,
      'medico_rut': medicoRut.trim(),
      'medico_nombre': medicoNombre.trim(),
      'inicio': DateTime.now().toUtc().toIso8601String(),
      'fin': fin.toUtc().toIso8601String(),
    };
    a['sello'] = await _selloAcceso(a);
    final lista = await StorageService.obtenerAccesosOffline();
    lista.add(a);
    await StorageService.guardarAccesosOffline(lista);
    return a['id_local'] as String;
  }

  /// La consulta terminó antes del plazo: el acceso se cierra ahora.
  static Future<void> cerrarAcceso(String idLocal) async {
    final lista = await StorageService.obtenerAccesosOffline();
    for (final a in lista) {
      if (a['id_local'] != idLocal) continue;
      final ahora = DateTime.now().toUtc();
      if (ahora.isBefore(DateTime.parse(a['fin'] as String))) {
        a['fin'] = ahora.toIso8601String();
        a['sello'] = await _selloAcceso(a);
      }
    }
    await StorageService.guardarAccesosOffline(lista);
  }

  /// Envía las notas pendientes. Sin red o con el servidor caído, quedan para
  /// la próxima vez. Una nota que la Ficha rechaza (sello alterado) se quita.
  /// Devuelve true si se envió al menos una (la ficha cambió: hay que recargarla).
  static Future<bool> enviarPendientes() async {
    if (_enviando) return false;
    _enviando = true;
    try {
      final token = await StorageService.obtenerToken();
      if (token == null || token.isEmpty) return false;
      await _enviarAccesos(token);
      final notas = await StorageService.obtenerNotasOffline();
      if (notas.isEmpty) return false;

      final listas = <String>{}; // enviadas (o rechazadas por alteradas)
      for (final nota in notas) {
        try {
          final res = await http.post(
            Uri.parse(AppConfig.notasOfflineEndpoint),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode(nota),
          );
          // 200 = recibida (en la ficha o para revisión); 422 = la Ficha la rechazó
          // (alterada): no sirve reintentar. Cualquier otro caso se reintenta.
          if (res.statusCode == 200 || res.statusCode == 422) listas.add(nota['id_local'] as String);
        } catch (_) {
          // sin red: queda para la próxima vez
        }
      }
      if (listas.isEmpty) return false;
      // Se vuelve a leer: pudo guardarse una nota nueva mientras se enviaba
      final actuales = await StorageService.obtenerNotasOffline();
      await StorageService.guardarNotasOffline(
          actuales.where((n) => !listas.contains(n['id_local'])).toList());
      return true;
    } finally {
      _enviando = false;
    }
  }

  static Future<void> _enviarAccesos(String token) async {
    final accesos = await StorageService.obtenerAccesosOffline();
    if (accesos.isEmpty) return;
    final listos = <String>{};
    for (final a in accesos) {
      try {
        final res = await http.post(
          Uri.parse(AppConfig.accesosOfflineEndpoint),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(a),
        );
        if (res.statusCode == 200 || res.statusCode == 422) listos.add(a['id_local'] as String);
      } catch (_) {
        // sin red: queda para la próxima vez
      }
    }
    if (listos.isEmpty) return;
    final actuales = await StorageService.obtenerAccesosOffline();
    await StorageService.guardarAccesosOffline(
        actuales.where((a) => !listos.contains(a['id_local'])).toList());
  }
}

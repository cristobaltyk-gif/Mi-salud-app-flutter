/// lib/services/copia_cifrada_service.dart — v1.1
///
/// v1.1: también guarda copias de las personas que el usuario cuida
/// (`rutCuidado`), con lo que su nivel de acceso le deja ver. leerJson()
/// entrega la ficha descifrada tal cual (la usa la consulta sin conexión).
///
/// Copia CIFRADA de la ficha en el teléfono, para leerla sin internet
/// ("billetera fría"). Pareja de misalud-backend routers/copia_cifrada_router.py.
///
/// - descargar(): pide la copia al servidor (AES-256-GCM, con la sesión del
///   paciente). El archivo cifrado queda en el sandbox de la app y su llave,
///   que entrega el servidor, en el almacenamiento seguro (Keystore/Keychain).
///   Sin esa llave el archivo no se puede leer.
/// - actualizarSiHaceFalta(): con la ficha abierta en línea, baja una copia
///   nueva si no hay o tiene más de 24 horas. Nunca interrumpe nada: sin
///   internet, la copia anterior se conserva.
/// - leer(): descifra en el teléfono y devuelve la ficha. Pide huella (o el PIN
///   del teléfono) salvo que la persona ya se haya identificado (pedirHuella:
///   false). Funciona sin internet y sin sesión.
/// - Si el teléfono no tiene ningún bloqueo de pantalla (huella, rostro, PIN)
///   no se guarda la copia.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'http_sesion.dart' as http;
import '../config/app_config.dart';
import '../models/evento_clinico.dart';
import '../models/ficha_cuidado.dart';
import 'biometria_service.dart';
import 'cuidador_service.dart';
import 'storage_service.dart';

class CopiaException implements Exception {
  final String mensaje;
  CopiaException(this.mensaje);
  @override
  String toString() => mensaje;
}

class CopiaCifradaService {
  static const Duration _vigencia = Duration(hours: 24);
  static const String _prefijoAad = 'misalud-copia|1|';
  static const int _largoMac = 16;
  static final Set<String> _actualizando = {};

  /// Hay una copia cifrada con su llave en este teléfono.
  static Future<bool> hayCopia({String? rutCuidado}) async {
    final llave = await StorageService.obtenerLlaveCopia(rut: rutCuidado);
    if (llave == null || llave.isEmpty) return false;
    return (await StorageService.archivoCopia(rut: rutCuidado)).exists();
  }

  /// Descarga la copia cifrada (necesita internet y sesión) y la guarda.
  static Future<void> descargar({String? rutCuidado}) async {
    final token = await StorageService.obtenerToken();
    if (token == null || token.isEmpty) {
      throw CopiaException('No hay sesión activa');
    }
    if (!await BiometriaService.disponible()) {
      throw CopiaException(
        'Para guardar tu ficha en este teléfono, activa un bloqueo de pantalla (huella, rostro o PIN).',
      );
    }

    final res = await http.get(
      Uri.parse(rutCuidado == null
          ? AppConfig.copiaFichaEndpoint
          : AppConfig.copiaCuidadoEndpoint(rutCuidado)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 403 && rutCuidado != null) {
      // Ya no hay vínculo con esa persona: su copia se borra de este teléfono
      await StorageService.borrarCopiaCuidado(rutCuidado);
      throw CopiaException('Ya no tienes acceso a la ficha de esta persona');
    }
    if (res.statusCode != 200) {
      throw CopiaException('No se pudo descargar la copia (${res.statusCode})');
    }

    final datos = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final llave = (datos['llave'] as String?) ?? '';
    final nonce = (datos['nonce'] as String?) ?? '';
    final cifrado = (datos['cifrado'] as String?) ?? '';
    final aad = (datos['aad'] as String?) ?? '';
    if (llave.isEmpty || nonce.isEmpty || cifrado.isEmpty || !aad.startsWith(_prefijoAad)) {
      throw CopiaException('La copia recibida está incompleta');
    }

    final archivo = await StorageService.archivoCopia(rut: rutCuidado);
    final temporal = File('${archivo.path}.tmp');
    await temporal.writeAsString(
      jsonEncode({
        'formato': datos['formato'],
        'version': datos['version'],
        'generado_at': datos['generado_at'],
        'aad': aad,
        'nonce': nonce,
        'cifrado': cifrado,
      }),
      flush: true,
    );
    await temporal.rename(archivo.path);
    await StorageService.guardarLlaveCopia(llave, rut: rutCuidado);
  }

  /// Con la ficha abierta en línea: baja una copia nueva si no hay o ya tiene
  /// más de 24 horas. Se llama sin esperar (no bloquea la pantalla).
  static Future<void> actualizarSiHaceFalta({String? rutCuidado}) async {
    final clave = rutCuidado ?? '';
    if (_actualizando.contains(clave)) return;
    _actualizando.add(clave);
    try {
      if (await hayCopia(rutCuidado: rutCuidado)) {
        final archivo = await StorageService.archivoCopia(rut: rutCuidado);
        final meta = jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;
        final generado = DateTime.tryParse((meta['generado_at'] as String?) ?? '');
        if (generado != null &&
            DateTime.now().toUtc().difference(generado.toUtc()) < _vigencia) {
          return;
        }
      }
      await descargar(rutCuidado: rutCuidado);
    } catch (_) {
      // Sin internet o sin bloqueo de pantalla: la copia anterior se conserva.
    } finally {
      _actualizando.remove(clave);
    }
  }

  /// Con red: deja al día (cada 24 h) las copias de todas las personas que el
  /// usuario cuida, aunque no haya abierto su ficha, y borra las de quienes
  /// ya no cuida. Nunca interrumpe nada.
  static Future<void> actualizarCuidados() async {
    try {
      final cuidados = await CuidadorService.misCuidados();
      for (final c in cuidados) {
        await actualizarSiHaceFalta(rutCuidado: c.rutPaciente);
      }
      final vigentes = cuidados.map((c) => c.rutPaciente).toSet();
      final dir = (await StorageService.archivoCopia()).parent;
      if (await dir.exists()) {
        await for (final f in dir.list()) {
          final nombre = f.uri.pathSegments.isEmpty ? '' : f.uri.pathSegments.last;
          if (!nombre.startsWith('copia_cuidado_') || !nombre.endsWith('.enc')) continue;
          final digitos = nombre.substring('copia_cuidado_'.length, nombre.length - 4);
          final rut = vigentes.firstWhere(
            (r) => r.replaceAll(RegExp(r'[^0-9kK]'), '') == digitos,
            orElse: () => '',
          );
          if (rut.isEmpty) await f.delete(); // ya no la cuida (su llave queda sin archivo)
        }
      }
    } catch (_) {
      // Sin internet: las copias anteriores se conservan.
    }
  }

  /// Descifra la copia propia y devuelve la ficha.
  static Future<FichaResumen> leer({bool pedirHuella = true}) async =>
      FichaResumen.fromJson(await leerJson(pedirHuella: pedirHuella));

  /// Descifra la copia de una persona cuidada (mismo formato que en línea).
  static Future<FichaCuidado> leerCuidado(String rutCuidado, {bool pedirHuella = false}) async =>
      FichaCuidado.fromJson(await leerJson(rutCuidado: rutCuidado, pedirHuella: pedirHuella));

  /// Descifra una copia y devuelve la ficha tal cual. Con pedirHuella pide
  /// huella o el PIN del teléfono antes; false solo si la persona ya se
  /// identificó recién (sesión abierta o huella de entrada).
  static Future<Map<String, dynamic>> leerJson({String? rutCuidado, bool pedirHuella = true}) async {
    if (pedirHuella) {
      final ok = await BiometriaService.autenticar(
        motivo: 'Confirma que eres tú para abrir la ficha',
      );
      if (!ok) {
        throw CopiaException(BiometriaService.ultimoError ?? 'No se confirmó tu identidad.');
      }
    }

    final llave = await StorageService.obtenerLlaveCopia(rut: rutCuidado);
    final archivo = await StorageService.archivoCopia(rut: rutCuidado);
    if (llave == null || llave.isEmpty || !await archivo.exists()) {
      throw CopiaException(rutCuidado == null
          ? 'No hay una copia de tu ficha guardada en este teléfono.'
          : 'No hay una copia de la ficha de esta persona en este teléfono.');
    }

    try {
      final meta = jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;
      final aad = meta['aad'] as String;
      if (!aad.startsWith(_prefijoAad)) {
        throw CopiaException('La copia guardada no es válida.');
      }
      final bytes = base64Decode(meta['cifrado'] as String);
      if (bytes.length <= _largoMac) {
        throw CopiaException('La copia guardada no es válida.');
      }

      // El servidor entrega texto cifrado + etiqueta de autenticación (16 bytes) juntos.
      final caja = SecretBox(
        bytes.sublist(0, bytes.length - _largoMac),
        nonce: base64Decode(meta['nonce'] as String),
        mac: Mac(bytes.sublist(bytes.length - _largoMac)),
      );
      final claro = await AesGcm.with256bits().decrypt(
        caja,
        secretKey: SecretKey(base64Decode(llave)),
        aad: utf8.encode(aad),
      );
      return jsonDecode(utf8.decode(claro)) as Map<String, dynamic>;
    } on CopiaException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw CopiaException(
        'La copia guardada está dañada o fue modificada. Conéctate a internet para descargarla de nuevo.',
      );
    } catch (_) {
      throw CopiaException('No se pudo abrir la copia guardada.');
    }
  }
}

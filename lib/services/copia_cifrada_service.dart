/// lib/services/copia_cifrada_service.dart — v1.0
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
import 'biometria_service.dart';
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
  static bool _actualizando = false;

  /// Hay una copia cifrada con su llave en este teléfono.
  static Future<bool> hayCopia() async {
    final llave = await StorageService.obtenerLlaveCopia();
    if (llave == null || llave.isEmpty) return false;
    return (await StorageService.archivoCopia()).exists();
  }

  /// Descarga la copia cifrada (necesita internet y sesión) y la guarda.
  static Future<void> descargar() async {
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
      Uri.parse(AppConfig.copiaFichaEndpoint),
      headers: {'Authorization': 'Bearer $token'},
    );
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

    final archivo = await StorageService.archivoCopia();
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
    await StorageService.guardarLlaveCopia(llave);
  }

  /// Con la ficha abierta en línea: baja una copia nueva si no hay o ya tiene
  /// más de 24 horas. Se llama sin esperar (no bloquea la pantalla).
  static Future<void> actualizarSiHaceFalta() async {
    if (_actualizando) return;
    _actualizando = true;
    try {
      if (await hayCopia()) {
        final archivo = await StorageService.archivoCopia();
        final meta = jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;
        final generado = DateTime.tryParse((meta['generado_at'] as String?) ?? '');
        if (generado != null &&
            DateTime.now().toUtc().difference(generado.toUtc()) < _vigencia) {
          return;
        }
      }
      await descargar();
    } catch (_) {
      // Sin internet o sin bloqueo de pantalla: la copia anterior se conserva.
    } finally {
      _actualizando = false;
    }
  }

  /// Descifra la copia y devuelve la ficha. Con pedirHuella (lo normal) pide
  /// huella o el PIN del teléfono antes; false solo si la persona ya se
  /// identificó recién (sesión abierta o huella de entrada).
  static Future<FichaResumen> leer({bool pedirHuella = true}) async {
    if (pedirHuella) {
      final ok = await BiometriaService.autenticar(
        motivo: 'Confirma que eres tú para abrir tu ficha',
      );
      if (!ok) {
        throw CopiaException(BiometriaService.ultimoError ?? 'No se confirmó tu identidad.');
      }
    }

    final llave = await StorageService.obtenerLlaveCopia();
    final archivo = await StorageService.archivoCopia();
    if (llave == null || llave.isEmpty || !await archivo.exists()) {
      throw CopiaException('No hay una copia de tu ficha guardada en este teléfono.');
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
      final ficha = jsonDecode(utf8.decode(claro)) as Map<String, dynamic>;
      return FichaResumen.fromJson(ficha);
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

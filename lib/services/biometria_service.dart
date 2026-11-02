/// lib/services/biometria_service.dart — v1.0
///
/// Ingreso con huella o rostro (local_auth). Si el teléfono no tiene huella
/// configurada, Android ofrece el PIN, patrón o contraseña del teléfono
/// (biometricOnly: false). Nunca lanza: devuelve false si no se pudo, y deja
/// el motivo en `ultimoError` para mostrarlo (v1.1: antes fallaba en silencio).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static String? ultimoError;

  /// El teléfono permite desbloquear con huella, rostro o su PIN/patrón.
  static Future<bool> disponible() async {
    ultimoError = null;
    try {
      final soportado = await _auth.isDeviceSupported();
      final huella = await _auth.canCheckBiometrics;
      if (!soportado && !huella) {
        ultimoError = 'El teléfono no tiene huella, rostro ni bloqueo de pantalla configurado.';
      }
      return soportado || huella;
    } catch (e) {
      ultimoError = 'No se pudo revisar la huella del teléfono ($e).';
      debugPrint('[huella] no disponible: $e');
      return false;
    }
  }

  /// Pide la huella (o el PIN del teléfono). true si la persona se identificó.
  static Future<bool> autenticar({String motivo = 'Confirma que eres tú para entrar a MiSalud'}) async {
    ultimoError = null;
    try {
      final ok = await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (!ok) ultimoError = 'No se confirmó la huella.';
      return ok;
    } on PlatformException catch (e) {
      ultimoError = 'La huella no está disponible: ${e.message ?? e.code}';
      debugPrint('[huella] ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      ultimoError = 'La huella no está disponible: $e';
      debugPrint('[huella] $e');
      return false;
    }
  }
}

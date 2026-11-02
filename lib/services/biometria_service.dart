/// lib/services/biometria_service.dart — v1.0
///
/// Ingreso con huella o rostro (local_auth). Si el teléfono no tiene huella
/// configurada, Android ofrece el PIN, patrón o contraseña del teléfono
/// (biometricOnly: false). Nunca lanza: devuelve false si no se pudo.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// El teléfono permite desbloquear con huella, rostro o su PIN/patrón.
  static Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[huella] no disponible: $e');
      return false;
    }
  }

  /// Pide la huella (o el PIN del teléfono). true si la persona se identificó.
  static Future<bool> autenticar({String motivo = 'Confirma que eres tú para entrar a MiSalud'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } on PlatformException catch (e) {
      debugPrint('[huella] ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[huella] $e');
      return false;
    }
  }
}

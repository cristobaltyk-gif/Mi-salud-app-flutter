/// lib/services/fcm_service.dart
///
/// Inicializa Firebase Cloud Messaging. Cuando llega un data message
/// (disparado por HypokratIA cada vez que ICA notifica un evento nuevo
/// o cambio de agenda), reprograma las alarmas locales sin que el
/// paciente tenga que abrir la app.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import 'alarm_service.dart';
import 'recordatorios_service.dart';
import 'storage_service.dart';

/// Debe ser función de nivel superior (no método de clase) y llevar
/// este pragma — Firebase la ejecuta en un isolate separado cuando
/// llega un mensaje con la app cerrada o en background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _reprogramarDesdeNotificacion();
}

Future<void> _reprogramarDesdeNotificacion() async {
  try {
    final recordatorios = await RecordatoriosService.misRecordatorios();
    await AlarmService.reprogramarTodas(recordatorios);
  } catch (e) {
    // Sin conexión o token expirado en este momento — no es crítico,
    // AlarmService.reprogramarDesdeStorage() ya cubre el caso de que
    // el próximo arranque de la app reprograme desde lo último guardado.
    // ignore: avoid_print
    print('Error reprogramando desde FCM: $e');
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: false,
      badge: false,
      sound: false,
    );

    // Mensaje recibido con la app abierta (foreground) — mismo tratamiento.
    FirebaseMessaging.onMessage.listen((message) async {
      await _reprogramarDesdeNotificacion();
    });

    final token = await _messaging.getToken();
    if (token != null) {
      await registrarTokenEnBackend(token);
    }

    // Firebase puede rotar el token — hay que volver a registrarlo si cambia.
    _messaging.onTokenRefresh.listen((nuevoToken) {
      registrarTokenEnBackend(nuevoToken);
    });

    _inicializado = true;
  }

  /// Envía el token FCM al backend para guardarlo asociado al paciente,
  /// vía POST /api/dispositivos/registrar.
  static Future<void> registrarTokenEnBackend(String token) async {
    try {
      final tokenSesion = await StorageService.obtenerToken();
      if (tokenSesion == null) return; // sin sesión activa, no hay a quién asociarlo

      await http.post(
        Uri.parse(AppConfig.dispositivosRegistrarEndpoint),
        headers: {
          'Authorization': 'Bearer $tokenSesion',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token, 'plataforma': 'android'}),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error registrando token FCM: $e');
    }
  }
}

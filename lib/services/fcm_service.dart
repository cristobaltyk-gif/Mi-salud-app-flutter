/// lib/services/fcm_service.dart
///
/// Inicializa Firebase Cloud Messaging. Cuando llega un data message
/// (disparado por HypokratIA cada vez que ICA notifica un evento nuevo
/// o cambio de agenda), reprograma las alarmas locales sin que el
/// paciente tenga que abrir la app.
///
/// v1.2 TEMPORAL — DIAGNÓSTICO. inicializar() acepta un callback
/// opcional onLog que se llama entre cada sub-paso interno. Usado
/// junto con la versión de diagnóstico de main.dart para ver en
/// pantalla exactamente cuál de los 6 pasos internos no completa.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import 'alarm_service.dart';
import 'recordatorios_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _reprogramarDesdeNotificacion();
}

Future<void> _reprogramarDesdeNotificacion() async {
  try {
    final recordatorios = await RecordatoriosService.misRecordatorios();
    await AlarmService.reprogramarTodas(recordatorios);
  } catch (e) {
    // ignore: avoid_print
    print('Error reprogramando desde FCM: $e');
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _inicializado = false;

  static Future<void> inicializar({void Function(String)? onLog}) async {
    void log(String texto) => onLog?.call(texto);

    if (_inicializado) {
      log('  (ya estaba inicializado, se omite)');
      return;
    }

    log('  → Firebase.initializeApp()...');
    await Firebase.initializeApp();
    log('  ✓ Firebase.initializeApp() ok');

    log('  → registrando background handler...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    log('  ✓ background handler registrado');

    log('  → requestPermission()...');
    await _messaging.requestPermission(
      alert: false,
      badge: false,
      sound: false,
    );
    log('  ✓ requestPermission() ok');

    log('  → registrando listener onMessage...');
    FirebaseMessaging.onMessage.listen((message) async {
      await _reprogramarDesdeNotificacion();
    });
    log('  ✓ listener onMessage registrado');

    log('  → getToken()...');
    final token = await _messaging.getToken();
    log('  ✓ getToken() ok: ${token != null ? "token obtenido" : "null"}');

    if (token != null) {
      log('  → registrarTokenEnBackend()...');
      await registrarTokenEnBackend(token);
      log('  ✓ registrarTokenEnBackend() ok');
    }

    log('  → registrando listener onTokenRefresh...');
    _messaging.onTokenRefresh.listen((nuevoToken) {
      registrarTokenEnBackend(nuevoToken);
    });
    log('  ✓ listener onTokenRefresh registrado');

    _inicializado = true;
  }

  static Future<void> registrarTokenEnBackend(String token) async {
    try {
      final tokenSesion = await StorageService.obtenerToken();
      if (tokenSesion == null) return;

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

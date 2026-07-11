/// lib/services/fcm_service.dart
///
/// Inicializa Firebase Cloud Messaging. Cuando llega un data message
/// (disparado por HypokratIA cada vez que ICA notifica un evento nuevo
/// o cambio de agenda), reprograma las alarmas locales sin que el
/// paciente tenga que abrir la app.
///
/// PENDIENTE del lado backend: el endpoint que recibe y guarda el
/// token FCM del dispositivo (tabla dispositivos_fcm) aún no existe
/// en misalud-backend. registrarTokenEnBackend() está armado pero
/// apunta a un endpoint que hay que crear antes de que esto funcione
/// de punta a punta.
library;

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

  /// Envía el token FCM al backend para guardarlo asociado al paciente.
  /// PENDIENTE: el endpoint /api/dispositivos/registrar (o el nombre que
  /// se decida) todavía no existe en misalud-backend — hay que crearlo
  /// junto con la tabla dispositivos_fcm antes de que este POST funcione.
  static Future<void> registrarTokenEnBackend(String token) async {
    try {
      final tokenSesion = await StorageService.obtenerToken();
      if (tokenSesion == null) return; // sin sesión activa, no hay a quién asociarlo

      // TODO: reemplazar por el endpoint real cuando exista en el backend.
      // await http.post(
      //   Uri.parse(AppConfig.dispositivosRegistrarEndpoint),
      //   headers: {
      //     'Authorization': 'Bearer $tokenSesion',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({'fcm_token': token, 'plataforma': 'android'}),
      // );
    } catch (e) {
      // ignore: avoid_print
      print('Error registrando token FCM: $e');
    }
  }
}

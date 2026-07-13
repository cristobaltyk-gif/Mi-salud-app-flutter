/// lib/services/fcm_service.dart
///
/// Inicializa Firebase Cloud Messaging. Cuando llega un data message
/// (disparado por HypokratIA cada vez que ICA notifica un evento nuevo
/// o cambio de agenda), reprograma las alarmas locales sin que el
/// paciente tenga que abrir la app.
///
/// v1.3 — se agrega manejo del tipo "recordatorio_ahora": lo manda
/// recordatorios_scheduler.py en el momento EXACTO en que un disparo
/// vence, con el título y cuerpo reales del recordatorio. Al
/// recibirlo, se muestra la notificación DE INMEDIATO vía
/// AlarmService.mostrarAhora() — no se re-sincroniza la lista, se
/// muestra directo. El tipo anterior (data sin "tipo" propio, o
/// "recordatorios_actualizados") sigue reprogramando como antes.
///
/// v1.2 TEMPORAL — DIAGNÓSTICO. inicializar() acepta un callback
/// opcional onLog que se llama entre cada sub-paso interno.
///
/// v1.4 — FIX: FcmService.inicializar() corre en main(), ANTES de que
/// exista sesión (main() se ejecuta antes de que LoginScreen/Dashboard
/// decidan qué mostrar). Por eso registrarTokenEnBackend() se salía en
/// silencio (StorageService.obtenerToken() == null) y, como
/// _inicializado quedaba en true igual, nunca se reintentaba — el
/// token FCM real nunca llegaba al backend. Se agrega
/// registrarTokenSiHaySesion(), método público que login_screen.dart
/// llama explícitamente justo después de un login exitoso, cuando ya
/// hay sesión guardada.
///
/// v1.5 — recordatorios_scheduler.py ahora manda media_path en el
/// data del mensaje "recordatorio_ahora" para recordatorios de
/// ejercicio (plan domiciliario de kinesiología). Se extrae acá y se
/// pasa a AlarmService.mostrarAhora(), que lo codifica en el payload
/// de la notificación — al tocarla, la app abre la foto o el video
/// dentro de MediaEjercicioScreen (ver alarm_service.dart).
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
  await _procesarMensaje(message);
}

Future<void> _procesarMensaje(RemoteMessage message) async {
  final tipo = message.data['tipo'];

  if (tipo == 'recordatorio_ahora') {
    final titulo = message.data['titulo'] ?? 'Recordatorio';
    final cuerpo = message.data['cuerpo'] ?? '';
    final mediaPath = message.data['media_path'] as String?;
    try {
      await AlarmService.inicializar();
      await AlarmService.mostrarAhora(
        titulo,
        cuerpo,
        mediaPath: (mediaPath != null && mediaPath.isNotEmpty) ? mediaPath : null,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error mostrando recordatorio inmediato: $e');
    }
    return;
  }

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
      await _procesarMensaje(message);
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

  /// Se llama explícitamente justo después de un login exitoso (ver
  /// login_screen.dart), cuando ya hay un JWT de sesión guardado en
  /// StorageService. FcmService ya está inicializado desde main(), así
  /// que _messaging.getToken() es inmediato (no vuelve a pedir
  /// permisos ni reinicializa Firebase) — solo se reusa el token que
  /// Firebase ya tenía y se reintenta el envío al backend, esta vez
  /// con sesión válida.
  static Future<void> registrarTokenSiHaySesion() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await registrarTokenEnBackend(token);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error registrando token FCM tras login: $e');
    }
  }
}

/// lib/services/alarm_service.dart
///
/// v1.2 — Se cubre también el caso de app completamente cerrada al
/// tocar la notificación: inicializar() consulta
/// getNotificationAppLaunchDetails() y, si la app se abrió por haber
/// tocado una notificación con media, navega a MediaEjercicioScreen
/// apenas la primera pantalla termina de dibujarse
/// (WidgetsBinding.addPostFrameCallback) — antes de eso el Navigator
/// todavía no tiene un estado válido para navegar. Reusa
/// _alTocarNotificacion() para no duplicar la lógica de parseo del
/// payload.
///
/// v1.1 — mostrarAhora() acepta mediaPath opcional (foto/video de
/// referencia de un ejercicio de plan domiciliario, ver
/// fcm_service.dart) y lo codifica en el payload de la notificación
/// como JSON. Se agrega el callback onDidReceiveNotificationResponse
/// en inicializar(): al tocar una notificación cuyo payload trae un
/// mediaPath no vacío, navega a MediaEjercicioScreen usando el
/// navigatorKey global (navigation_service.dart) — necesario porque
/// este callback corre sin BuildContext disponible. Las notificaciones
/// programadas con anticipación (medicamentos/agenda, sin media) usan
/// el payload viejo 'recordatorio:ID', que no es JSON válido — el
/// callback lo detecta y no hace nada especial en ese caso.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../models/recordatorio.dart';
import '../screens/media_ejercicio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'navigation_service.dart';

void _alTocarNotificacion(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final mediaPath = data['mediaPath'] as String?;
    if (mediaPath == null || mediaPath.isEmpty) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MediaEjercicioScreen(
          titulo: data['titulo'] as String? ?? 'Recordatorio',
          cuerpo: data['cuerpo'] as String? ?? '',
          mediaPath: mediaPath,
        ),
      ),
    );
  } catch (_) {
    // Payload viejo tipo 'recordatorio:ID' (alarmas programadas sin
    // media) — no es JSON, no hace nada especial al tocarlo.
  }
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Santiago'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _alTocarNotificacion,
    );

    await _crearCanalAndroid();
    await _manejarLanzamientoDesdeNotificacion();
    _inicializado = true;
  }

  /// Cubre el caso "app completamente cerrada, se abre porque tocaron
  /// una notificación". En ese caso onDidReceiveNotificationResponse
  /// no llega a dispararse solo con initialize() — hay que preguntar
  /// explícitamente si el lanzamiento vino de una notificación, y
  /// recién navegar una vez que exista un frame dibujado (el
  /// navigatorKey no tiene estado válido antes de eso).
  static Future<void> _manejarLanzamientoDesdeNotificacion() async {
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    if (detalles == null || !detalles.didNotificationLaunchApp) return;

    final response = detalles.notificationResponse;
    if (response == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alTocarNotificacion(response);
    });
  }

  static Future<void> _crearCanalAndroid() async {
    if (!Platform.isAndroid) return;

    const canal = AndroidNotificationChannel(
      AppConfig.notifChannelId,
      AppConfig.notifChannelName,
      description: AppConfig.notifChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(AppConfig.alarmSoundName),
      enableVibration: true,
      vibrationPattern: null,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  static Future<bool> pedirPermisos() async {
    if (Platform.isAndroid) {
      final notif = await Permission.notification.request();

      var alarmaExacta = await Permission.scheduleExactAlarm.status;
      if (!alarmaExacta.isGranted) {
        alarmaExacta = await Permission.scheduleExactAlarm.request();
      }

      if (!alarmaExacta.isGranted) {
        await openAppSettings();
      }

      return notif.isGranted && alarmaExacta.isGranted;
    }
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  // v3: el teléfono calcula las tomas con la regla de cada recordatorio
  // (Recordatorio.horariosDesde) y deja programadas las más cercanas. Suenan
  // hasta donde termina la receta, sin sesión ni internet. Se recalcula al
  // abrir la app, al reiniciar el teléfono, con cada aviso del servidor y con
  // el aviso silencioso diario (fcm_service.dart).
  // Android permite ~500 alarmas por app: tope de 400, las más cercanas.
  static const int _maxAlarmas = 400;

  static int _idAlarma(int recordatorioId, DateTime cuando) =>
      (recordatorioId * 100003 + cuando.toUtc().millisecondsSinceEpoch ~/ 60000) & 0x7fffffff;

  static Future<void> _programarLista(List<Recordatorio> recordatorios) async {
    await _plugin.cancelAll();
    final ahora = DateTime.now();
    final tomas = <(Recordatorio, DateTime)>[];
    for (final r in recordatorios) {
      for (final h in r.horariosDesde(ahora, maximo: _maxAlarmas)) {
        tomas.add((r, h));
      }
    }
    tomas.sort((a, b) => a.$2.compareTo(b.$2));
    final programadas = <String>[];
    for (final (r, horario) in tomas.take(_maxAlarmas)) {
      if (await _programarUna(r, horario, _idAlarma(r.id, horario))) {
        programadas.add(_claveToma(r.id, horario));
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      // Se conservan las que ya sonaron hace poco: el aviso del servidor
      // puede llegar hasta una hora después y no debe repetirse.
      final desde = ahora.toUtc().millisecondsSinceEpoch ~/ 60000 - 180;
      final recientes = (prefs.getStringList(_prefsProgramadas) ?? const <String>[]).where((k) {
        final m = int.tryParse(k.split('@').last) ?? 0;
        return m >= desde && m <= ahora.toUtc().millisecondsSinceEpoch ~/ 60000;
      });
      await prefs.setStringList(_prefsProgramadas, {...recientes, ...programadas}.toList());
    } catch (_) {}
  }

  static const String _prefsProgramadas = 'misalud_alarmas_programadas';
  static String _claveToma(int recordatorioId, DateTime cuando) =>
      '$recordatorioId@${cuando.toUtc().millisecondsSinceEpoch ~/ 60000}';

  static Future<void> reprogramarTodas(List<Recordatorio> recordatorios) async {
    await StorageService.guardarRecordatorios(
      recordatorios.map((r) => r.toJson()).toList(),
    );
    await _programarLista(recordatorios);
  }

  static Future<void> reprogramarDesdeStorage() async {
    try {
      final raw = await StorageService.obtenerRecordatorios();
      if (raw.isEmpty) return;
      await _programarLista(raw.map((e) => Recordatorio.fromJson(e)).toList());
    } catch (_) {}
  }

  /// ¿Esta toma ya estaba programada en el teléfono? (para no repetir el
  /// aviso push del servidor — fcm_service.dart)
  /// Solo cuenta si la alarma se programó de verdad (si el teléfono no dio
  /// permiso de alarmas exactas, el aviso del servidor sí se muestra).
  static Future<bool> tomaProgramadaEnTelefono(int recordatorioId, DateTime programadoPara) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();   // puede venir de otro isolate (FCM en segundo plano)
      final lista = prefs.getStringList(_prefsProgramadas) ?? const [];
      final minuto = programadoPara.toUtc().millisecondsSinceEpoch ~/ 60000;
      return [minuto - 1, minuto, minuto + 1].any((m) => lista.contains('$recordatorioId@$m'));
    } catch (_) {}
    return false;
  }

  /// true solo si quedó programada a la hora EXACTA. Si quedó aproximada
  /// (sin el permiso "Alarmas y recordatorios") devuelve false: así el aviso
  /// del servidor también suena y no se depende de una alarma atrasada.
  static Future<bool> _programarUna(Recordatorio r, DateTime cuando, int idAlarma) async {
    final horario = tz.TZDateTime.from(cuando, tz.local);
    if (horario.isBefore(tz.TZDateTime.now(tz.local))) return false;

    final androidDetails = AndroidNotificationDetails(
      AppConfig.notifChannelId,
      AppConfig.notifChannelName,
      channelDescription: AppConfig.notifChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(AppConfig.alarmSoundName),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      ticker: 'Hora de tu medicamento',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '${AppConfig.alarmSoundName}.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    // Exacta si el usuario dio el permiso "Alarmas y recordatorios"; si no
    // (Android 14+ lo trae apagado y la app de Google Play ya no usa
    // USE_EXACT_ALARM), igual se programa, aunque Android puede atrasarla
    // unos minutos. El aviso del servidor (FCM) sigue de respaldo.
    for (final modo in [AndroidScheduleMode.exactAllowWhileIdle, AndroidScheduleMode.inexactAllowWhileIdle]) {
      try {
        await _plugin.zonedSchedule(
          idAlarma,
          'Hora de tu medicamento',
          r.textoMostrar,
          horario,
          NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: modo,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'recordatorio:${r.id}',
        );
        return modo == AndroidScheduleMode.exactAllowWhileIdle;
      } catch (_) {}
    }
    return false;
  }

  static Future<void> cancelarTodas() => _plugin.cancelAll();

  static Future<void> cancelar(int recordatorioId) async {
    await _plugin.cancel(recordatorioId);   // id antiguo (una sola alarma)
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getStringList(_prefsProgramadas) ?? const <String>[]) {
        final partes = k.split('@');
        if (partes.first != '$recordatorioId') continue;
        final minuto = int.tryParse(partes.last);
        if (minuto == null) continue;
        await _plugin.cancel(_idAlarma(recordatorioId,
            DateTime.fromMillisecondsSinceEpoch(minuto * 60000, isUtc: true)));
      }
    } catch (_) {}
  }

  /// Muestra la notificación DE INMEDIATO, sin programar nada con
  /// anticipación — se llama cuando llega un FCM tipo "recordatorio_ahora"
  /// con el contenido real del recordatorio (ver fcm_service.dart), justo
  /// en el momento en que el servidor determinó que corresponde sonar.
  /// Mismo patrón que WhatsApp: el mensaje llega, se muestra ahí mismo.
  ///
  /// mediaPath: ruta del archivo (foto/video) en Supabase Storage, para
  /// recordatorios de ejercicio. Se codifica en el payload como JSON;
  /// al tocar la notificación (app abierta, en background, o
  /// completamente cerrada), se navega a MediaEjercicioScreen. Si es
  /// null/vacío (medicamentos, agenda, indicaciones), la notificación
  /// se muestra igual pero tocarla no abre nada especial.
  static Future<void> mostrarAhora(String titulo, String cuerpo, {String? mediaPath}) async {
    final androidDetails = AndroidNotificationDetails(
      AppConfig.notifChannelId,
      AppConfig.notifChannelName,
      channelDescription: AppConfig.notifChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(AppConfig.alarmSoundName),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      ticker: titulo,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '${AppConfig.alarmSoundName}.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final payload = jsonEncode({
      'titulo': titulo,
      'cuerpo': cuerpo,
      'mediaPath': mediaPath ?? '',
    });

    await _plugin.show(
      id,
      titulo,
      cuerpo,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}

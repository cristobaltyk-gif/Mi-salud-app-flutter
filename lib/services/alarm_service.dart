/// lib/services/alarm_service.dart
library;

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../models/recordatorio.dart';
import 'storage_service.dart';

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
    );

    await _crearCanalAndroid();
    _inicializado = true;
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

  static Future<void> reprogramarTodas(List<Recordatorio> recordatorios) async {
    await StorageService.guardarRecordatorios(
      recordatorios.map((r) => r.toJson()).toList(),
    );
    await _plugin.cancelAll();
    for (final r in recordatorios) {
      if (r.proximoDisparo == null) continue;
      await _programarUna(r);
    }
  }

  static Future<void> reprogramarDesdeStorage() async {
    try {
      final raw = await StorageService.obtenerRecordatorios();
      if (raw.isEmpty) return;
      final recordatorios = raw.map((e) => Recordatorio.fromJson(e)).toList();
      await _plugin.cancelAll();
      for (final r in recordatorios) {
        if (r.proximoDisparo == null) continue;
        await _programarUna(r);
      }
    } catch (_) {}
  }

  static Future<void> _programarUna(Recordatorio r) async {
    final horario = tz.TZDateTime.from(r.proximoDisparo!, tz.local);
    if (horario.isBefore(tz.TZDateTime.now(tz.local))) return;

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

    try {
      await _plugin.zonedSchedule(
        r.id,
        'Hora de tu medicamento',
        r.textoMostrar,
        horario,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'recordatorio:${r.id}',
      );
    } catch (_) {}
  }

  static Future<void> cancelarTodas() => _plugin.cancelAll();

  static Future<void> cancelar(int recordatorioId) =>
      _plugin.cancel(recordatorioId);

  /// Muestra la notificación DE INMEDIATO, sin programar nada con
  /// anticipación — se llama cuando llega un FCM tipo "recordatorio_ahora"
  /// con el contenido real del recordatorio (ver fcm_service.dart), justo
  /// en el momento en que el servidor determinó que corresponde sonar.
  /// Mismo patrón que WhatsApp: el mensaje llega, se muestra ahí mismo.
  static Future<void> mostrarAhora(String titulo, String cuerpo) async {
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

    await _plugin.show(
      id,
      titulo,
      cuerpo,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}

/// lib/services/alarm_service.dart
///
/// Programa ALARMAS LOCALES en el dispositivo a partir de los horarios
/// que retorna el backend (campo `proximo_disparo` de cada Recordatorio).
///
/// Importante — límites reales de la plataforma (explicados al usuario
/// antes de construir esto):
///   - Android: con flutter_local_notifications + canal de alta prioridad,
///     sonido custom, y `fullScreenIntent: true`, se logra una alarma que
///     suena fuerte y puede mostrar una pantalla incluso con el teléfono
///     bloqueado. Esto SÍ se acerca al comportamiento de un despertador.
///   - iOS: las notificaciones locales NO pueden forzar pantalla completa
///     ni saltarse Modo No Molestar salvo que la app tenga el entitlement
///     de "Critical Alerts" aprobado por Apple (trámite aparte, pendiente).
///
/// v1.1: FIX — zonedSchedule() en flutter_local_notifications 18.0.1
/// todavía exige el parámetro `uiLocalNotificationDateInterpretation`
/// (removido en versiones posteriores). Se agrega con valor
/// `absoluteTime` — el horario ya viene en hora absoluta de Chile.
library;

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../models/recordatorio.dart';

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
      final alarmaExacta = await Permission.scheduleExactAlarm.request();
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
    await _plugin.cancelAll();

    for (final r in recordatorios) {
      if (r.proximoDisparo == null) continue;
      await _programarUna(r);
    }
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
  }

  static Future<void> cancelarTodas() => _plugin.cancelAll();

  static Future<void> cancelar(int recordatorioId) =>
      _plugin.cancel(recordatorioId);
}

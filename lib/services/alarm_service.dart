/// lib/services/alarm_service.dart
///
/// v1.2: agrega reprogramarDesdeStorage() — lee los recordatorios
/// guardados localmente y reprograma las alarmas sin necesitar token
/// ni conexión al backend. Se llama desde main.dart al arrancar la app,
/// ANTES de verificar sesión, para que las alarmas funcionen aunque
/// el token haya expirado.
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

  /// Reprograma alarmas desde el backend (requiere token válido).
  /// Guarda los recordatorios en storage para uso offline.
  static Future<void> reprogramarTodas(List<Recordatorio> recordatorios) async {
    // Guardar en storage para poder reprogramar sin token
    await StorageService.guardarRecordatorios(
      recordatorios.map((r) => r.toJson()).toList(),
    );
    await _plugin.cancelAll();
    for (final r in recordatorios) {
      if (r.proximoDisparo == null) continue;
      await _programarUna(r);
    }
  }

  /// Reprograma alarmas desde storage local — no necesita token ni
  /// conexión. Se llama al arrancar la app para que las alarmas
  /// funcionen aunque el token haya expirado.
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
    } catch (_) {
      // Si falla (primera instalación, datos corruptos), no crashear
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

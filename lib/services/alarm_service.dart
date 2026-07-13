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

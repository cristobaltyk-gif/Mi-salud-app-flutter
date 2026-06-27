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
///     Sin ese entitlement, en iOS esto se comporta como una notificación
///     normal con sonido — no como un despertador.
///
/// La app NO depende de que el servidor mande push en el segundo exacto:
/// cada vez que se sincronizan los recordatorios, se reprograman las
/// alarmas LOCALES correspondientes. Esto es más confiable que depender
/// de Web Push para algo tan sensible como un horario de medicamento.
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

  /// Debe llamarse una sola vez, al arrancar la app (en main.dart).
  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Santiago'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // Nota: critical alerts en iOS requieren entitlement aprobado por
      // Apple. Sin él, este flag no tiene efecto — queda documentado
      // para cuando se solicite y se agregue.
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _crearCanalAndroid();
    _inicializado = true;
  }

  /// Canal de Android dedicado a las alarmas — separado de notificaciones
  /// normales para que el paciente pueda configurar su volumen/sonido
  /// de forma independiente desde Ajustes del sistema.
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
      vibrationPattern: null, // null = patrón largo por defecto del sistema
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  /// Pide los permisos necesarios. Debe llamarse después de inicializar(),
  /// idealmente en una pantalla que explique por qué se necesitan (no al
  /// arrancar la app en frío, para no asustar al paciente con un permiso
  /// sin contexto).
  static Future<bool> pedirPermisos() async {
    if (Platform.isAndroid) {
      final notif = await Permission.notification.request();
      // Android 12+ (API 31+) exige permiso explícito para alarmas exactas;
      // sin esto, el sistema puede demorar la alarma varios minutos.
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

  /// Reprograma TODAS las alarmas a partir de la lista vigente de
  /// recordatorios. Se llama cada vez que se sincroniza con el backend
  /// (al abrir la app, al volver del background, o tras editar un
  /// recordatorio). Cancela las anteriores primero para no duplicar.
  static Future<void> reprogramarTodas(List<Recordatorio> recordatorios) async {
    await _plugin.cancelAll();

    for (final r in recordatorios) {
      if (r.proximoDisparo == null) continue; // sin disparo pendiente
      await _programarUna(r);
    }
  }

  static Future<void> _programarUna(Recordatorio r) async {
    final horario = tz.TZDateTime.from(r.proximoDisparo!, tz.local);

    // Si por alguna razón el horario ya pasó (reloj del teléfono distinto
    // al servidor, app abierta tarde, etc.), no programar en el pasado.
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
      fullScreenIntent: true, // intenta mostrar pantalla completa, incluso bloqueado
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true, // no se puede deslizar para descartar por accidente
      autoCancel: false,
      ticker: 'Hora de tu medicamento',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '${AppConfig.alarmSoundName}.caf',
      // interruptionLevel: critical requiere el entitlement de Apple
      // mencionado arriba. Se deja en .timeSensitive como el máximo
      // alcanzable sin ese trámite.
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.zonedSchedule(
      r.id, // usamos el id del recordatorio como id de notificación — único y estable
      'Hora de tu medicamento',
      r.textoMostrar,
      horario,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'recordatorio:${r.id}',
    );
  }

  static Future<void> cancelarTodas() => _plugin.cancelAll();

  static Future<void> cancelar(int recordatorioId) =>
      _plugin.cancel(recordatorioId);
}

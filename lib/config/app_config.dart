/// lib/config/app_config.dart
///
/// Configuración central de la app MiSalud.
/// IMPORTANTE: BACKEND_BASE_URL es la ÚNICA línea que debes editar
/// cuando confirmes la URL real del backend de MiSalud en Render.
/// No hay otra copia de esta URL en ningún otro archivo del proyecto.
library;

class AppConfig {
  AppConfig._(); // no instanciable

  /// TODO(cristobal): reemplazar por la URL real del servicio MiSalud en Render.
  /// Ejemplo de formato esperado: https://misalud-backend.onrender.com
  /// o el dominio propio si lo tienes: https://api.misalud.icarticular.cl
  static const String backendBaseUrl = 'https://REEMPLAZAR-URL-BACKEND-MISALUD.onrender.com';

  // --- Endpoints de autenticación (auth_router.py, prefix /api/auth) ---
  static const String authBase = '$backendBaseUrl/api/auth';
  static const String loginEndpoint = '$authBase/login';
  static const String buscarRutEndpoint = '$authBase/buscar';
  static const String activarCuentaEndpoint = '$authBase/activar';
  static const String registroEndpoint = '$authBase/registro';
  static const String meEndpoint = '$authBase/me';
  static const String cambiarPasswordEndpoint = '$authBase/cambiar-password';

  // --- Endpoints de ficha clínica (ficha_router.py, prefix /api/ficha) ---
  static const String fichaBase = '$backendBaseUrl/api/ficha';
  static const String fichaResumenEndpoint = '$fichaBase/resumen';
  static const String fichaExplicarEndpoint = '$fichaBase/explicar'; // SSE
  static String fichaEventoExplicarEndpoint(int eventoId) =>
      '$fichaBase/evento/$eventoId'; // SSE

  // --- Endpoints de recordatorios (recordatorios_router.py, prefix /api/recordatorios) ---
  static const String recordatoriosBase = '$backendBaseUrl/api/recordatorios';
  static String recordatoriosGenerarEndpoint(int eventoId) =>
      '$recordatoriosBase/generar/$eventoId';
  static const String recordatoriosMisRecordatoriosEndpoint =
      '$recordatoriosBase/mis-recordatorios';
  static String recordatorioEditarEndpoint(int recordatorioId) =>
      '$recordatoriosBase/$recordatorioId';

  /// NOTA: no existe (aún) un endpoint para marcar un DISPARO individual
  /// como "tomado" por el paciente — eso solo lo hace el scheduler del
  /// servidor al enviar el push. Pendiente de construir en el backend.
  /// Por ahora alarm_service.dart maneja el estado "tomado" solo en
  /// memoria/local, sin avisar al servidor.

  // --- Endpoints de cuidador (cuidador_router.py, prefix /api/cuidador) ---
  static const String cuidadorBase = '$backendBaseUrl/api/cuidador';
  static const String cuidadorInvitarEndpoint = '$cuidadorBase/invitar';
  static const String cuidadorNivelesAccesoEndpoint = '$cuidadorBase/niveles-acceso';
  static const String cuidadorMisInvitacionesEndpoint = '$cuidadorBase/mis-invitaciones';
  static String cuidadorRevocarInvitacionEndpoint(int invitacionId) =>
      '$cuidadorBase/invitar/$invitacionId';
  static String cuidadorRevocarVinculoEndpoint(int vinculoId) =>
      '$cuidadorBase/vinculo/$vinculoId';
  static const String cuidadorEscanearEndpoint = '$cuidadorBase/escanear';
  static const String cuidadorMisCuidadosEndpoint = '$cuidadorBase/mis-cuidados';

  // --- Almacenamiento local (shared_preferences keys) ---
  static const String prefsJwtKey = 'misalud_jwt_token';
  static const String prefsRutKey = 'misalud_rut_paciente';
  static const String prefsNombreKey = 'misalud_nombre_paciente';

  // --- Notificaciones / Alarmas ---
  static const String notifChannelId = 'misalud_alarmas_medicamentos';
  static const String notifChannelName = 'Alarmas de medicamentos';
  static const String notifChannelDescription =
      'Alarmas sonoras para recordatorios de medicamentos y controles';

  /// Nombre del archivo de sonido (sin extensión) usado como alarma.
  /// Debe existir como assets/sounds/alarma.mp3 Y como
  /// android/app/src/main/res/raw/alarma.mp3 (Android exige el sonido
  /// de notificación empaquetado nativamente, no solo como Flutter asset).
  static const String alarmSoundName = 'alarma';
}

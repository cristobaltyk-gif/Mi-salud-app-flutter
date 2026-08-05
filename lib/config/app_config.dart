/// lib/config/app_config.dart
///
/// Configuración central de la app MiSalud.
library;

class AppConfig {
  AppConfig._(); // no instanciable

  static const String backendBaseUrl = 'https://misalud-backend.onrender.com';

  /// Backend de ICA (distinto del backend de MiSalud) — usado solo para
  /// descargar PDFs clínicos (Documentospdf/pdfPacienteRouter.py).
  static const String icaBaseUrl = 'https://services.icarticular.cl';

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

  static String fichaCuidadoEndpoint(String rutPaciente) =>
      '$fichaBase/cuidado/$rutPaciente';

  // --- Endpoints de PDF clínico (Documentospdf/pdfPacienteRouter.py,
  //     backend de ICA, prefix /api/paciente/pdf) ---
  static String pdfDescargarEndpoint(int eventoId, String tipo, {String? rutPaciente}) {
    final base = '$icaBaseUrl/api/paciente/pdf/$eventoId/$tipo';
    return rutPaciente != null ? '$base?rut_paciente=$rutPaciente' : base;
  }

  // --- Endpoints de recordatorios (recordatorios_router.py, prefix /api/recordatorios) ---
  static const String recordatoriosBase = '$backendBaseUrl/api/recordatorios';
  static String recordatoriosGenerarEndpoint(int eventoId) =>
      '$recordatoriosBase/generar/$eventoId';
  static const String recordatoriosGenerarAgendaEndpoint =
      '$recordatoriosBase/generar-agenda';
  static const String recordatoriosMisRecordatoriosEndpoint =
      '$recordatoriosBase/mis-recordatorios';
  static String recordatorioEditarEndpoint(int recordatorioId) =>
      '$recordatoriosBase/$recordatorioId';

  // --- Endpoints de dispositivos (dispositivos_router.py, prefix /api/dispositivos) ---
  static const String dispositivosBase = '$backendBaseUrl/api/dispositivos';
  static const String dispositivosRegistrarEndpoint = '$dispositivosBase/registrar';

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

  // --- Endpoints de ficha compartida (ficha_compartida_router.py, prefix /api/compartir) ---
  static const String compartirBase = '$backendBaseUrl/api/compartir';
  static const String compartirGenerarEndpoint = '$compartirBase/generar';
  static const String compartirMisLinksEndpoint = '$compartirBase/mis-links';
  static String compartirRevocarEndpoint(int linkId) =>
      '$compartirBase/$linkId';
  static const String compartirEnviarEndpoint = '$compartirBase/enviar';

  // --- Endpoint de perfil público RNPI (rnpi.py, prefix /api/rnpi) ---
  // Dato público, sin auth — muestra al paciente quién es el médico
  // que ingresó a su ficha compartida (nombre, título, especialidad).
  static const String rnpiBase = '$backendBaseUrl/api/rnpi';
  static String rnpiPerfilPublicoEndpoint(String rut) =>
      '$rnpiBase/perfil-publico/$rut';

  // --- Endpoints del cotizador (cotizador_router.py, prefix /api/cotizador) ---
  static const String cotizadorBase = '$backendBaseUrl/api/cotizador';
  static const String cotizadorCotizarEndpoint = '$cotizadorBase/cotizar';

  // --- Almacenamiento local (shared_preferences keys) ---
  static const String prefsJwtKey = 'misalud_jwt_token';
  static const String prefsRutKey = 'misalud_rut_paciente';
  static const String prefsNombreKey = 'misalud_nombre_paciente';
  static const String prefsRecordatoriosKey = 'misalud_recordatorios';

  // --- Notificaciones / Alarmas ---
  static const String notifChannelId = 'misalud_alarmas_medicamentos';
  static const String notifChannelName = 'Alarmas de medicamentos';
  static const String notifChannelDescription =
      'Alarmas sonoras para recordatorios de medicamentos y controles';

  static const String alarmSoundName = 'alarma';

  // --- Supabase Storage (foto/video de referencia de ejercicios de
  //     plan domiciliario, bucket público 'kinesiologia') ---
  static const String supabaseStoragePublicUrl =
      'https://lixsezfbzetvaikvsazp.supabase.co/storage/v1/object/public/kinesiologia';
}

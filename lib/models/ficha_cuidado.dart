/// lib/models/ficha_cuidado.dart
///
/// Representa la respuesta de GET /api/ficha/cuidado/{rut_paciente}
/// (ficha_router.py v1.5). El shape depende de `nivelAcceso`:
///   - "medicamentos": solo `recordatorios` viene poblado.
///   - "indicaciones": `recordatorios` + `eventosConIndicaciones`.
///   - "completo": todos los campos, igual que FichaResumen del propio paciente.
///
/// EventoCuidadoCompleto incluye los campos clínicos completos (receta,
/// indicaciones, examenes, ordenKinesiologia, indicacionQuirurgica,
/// fotosDermatologia), tomados de `contenido` en la respuesta real del
/// backend (_contenido_limpio en ficha_router.py) — necesarios para
/// mostrar detalle expandible, PDF y galería de fotos en Flutter.
library;

import 'recordatorio.dart';

class PacienteCuidadoInfo {
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? fechaNacimiento;
  final String? sexo;

  PacienteCuidadoInfo({
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.fechaNacimiento,
    this.sexo,
  });

  factory PacienteCuidadoInfo.fromJson(Map<String, dynamic> json) {
    return PacienteCuidadoInfo(
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellido_paterno'] ?? '',
      apellidoMaterno: json['apellido_materno'],
      fechaNacimiento: json['fecha_nacimiento'],
      sexo: json['sexo'],
    );
  }

  String get nombreCompleto =>
      '$nombre $apellidoPaterno${(apellidoMaterno?.isNotEmpty ?? false) ? ' $apellidoMaterno' : ''}'.trim();
}

/// Evento con indicaciones, usado solo en nivel "indicaciones".
class EventoConIndicaciones {
  final int id;
  final String fecha;
  final String tipo;
  final String indicaciones;

  EventoConIndicaciones({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.indicaciones,
  });

  factory EventoConIndicaciones.fromJson(Map<String, dynamic> json) {
    return EventoConIndicaciones(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? '',
      indicaciones: json['indicaciones'] ?? '',
    );
  }
}

/// Foto adjunta a un evento (ej. dermatología). Igual estructura que
/// fotos_dermatologia en la web: { comentario, data (base64) }.
class FotoEvento {
  final String comentario;
  final String data;

  FotoEvento({required this.comentario, required this.data});

  factory FotoEvento.fromJson(Map<String, dynamic> json) {
    return FotoEvento(
      comentario: json['comentario'] ?? '',
      data: json['data'] ?? '',
    );
  }
}

/// Evento clínico completo, usado solo en nivel "completo".
class EventoCuidadoCompleto {
  final int id;
  final String fecha;
  final String tipo;
  final String medico;
  final String diagnostico;
  final String receta;
  final String indicaciones;
  final String examenes;
  final String ordenKinesiologia;
  final String indicacionQuirurgica;
  final List<FotoEvento> fotosDermatologia;

  EventoCuidadoCompleto({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.medico,
    required this.diagnostico,
    this.receta = '',
    this.indicaciones = '',
    this.examenes = '',
    this.ordenKinesiologia = '',
    this.indicacionQuirurgica = '',
    this.fotosDermatologia = const [],
  });

  factory EventoCuidadoCompleto.fromJson(Map<String, dynamic> json) {
    final contenido = json['contenido'] as Map<String, dynamic>? ?? {};
    final fotosRaw = contenido['fotos_dermatologia'] as List<dynamic>? ?? [];

    return EventoCuidadoCompleto(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? '',
      medico: json['medico'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      receta: contenido['receta'] ?? '',
      indicaciones: contenido['indicaciones'] ?? '',
      examenes: contenido['examenes'] ?? '',
      ordenKinesiologia: contenido['orden_kinesiologia'] ?? '',
      indicacionQuirurgica: contenido['indicacion_quirurgica'] ?? '',
      fotosDermatologia: fotosRaw
          .map((f) => FotoEvento.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  /// true si hay algún campo de detalle (texto o fotos) además del
  /// diagnóstico — usado para decidir si mostrar el botón "Ver detalle".
  bool get tieneDetalle =>
      receta.trim().isNotEmpty ||
      indicaciones.trim().isNotEmpty ||
      examenes.trim().isNotEmpty ||
      ordenKinesiologia.trim().isNotEmpty ||
      indicacionQuirurgica.trim().isNotEmpty ||
      fotosDermatologia.isNotEmpty;
}

class FichaCuidado {
  final String nivelAcceso; // "medicamentos" | "indicaciones" | "completo"
  final PacienteCuidadoInfo paciente;
  final List<Recordatorio> recordatorios;

  // Solo poblado si nivelAcceso == "indicaciones"
  final List<EventoConIndicaciones> eventosConIndicaciones;

  // Solo poblado si nivelAcceso == "completo"
  final int? totalConsultas;
  final Map<String, dynamic>? antecedentes;
  final List<EventoCuidadoCompleto> eventos;

  FichaCuidado({
    required this.nivelAcceso,
    required this.paciente,
    required this.recordatorios,
    this.eventosConIndicaciones = const [],
    this.totalConsultas,
    this.antecedentes,
    this.eventos = const [],
  });

  factory FichaCuidado.fromJson(Map<String, dynamic> json) {
    return FichaCuidado(
      nivelAcceso: json['nivel_acceso'] ?? '',
      paciente: PacienteCuidadoInfo.fromJson(json['paciente'] as Map<String, dynamic>? ?? {}),
      recordatorios: (json['recordatorios'] as List<dynamic>? ?? [])
          .map((r) => Recordatorio.fromJson(r as Map<String, dynamic>))
          .toList(),
      eventosConIndicaciones: (json['eventos_con_indicaciones'] as List<dynamic>? ?? [])
          .map((e) => EventoConIndicaciones.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalConsultas: json['total_consultas'],
      antecedentes: json['antecedentes'] as Map<String, dynamic>?,
      eventos: (json['eventos'] as List<dynamic>? ?? [])
          .map((e) => EventoCuidadoCompleto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get esMedicamentos => nivelAcceso == 'medicamentos';
  bool get esIndicaciones => nivelAcceso == 'indicaciones';
  bool get esCompleto => nivelAcceso == 'completo';
}

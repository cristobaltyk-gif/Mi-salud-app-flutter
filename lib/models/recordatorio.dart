/// lib/models/recordatorio.dart
///
/// Representa una fila de la tabla `recordatorios`, tal como la retorna
/// GET /api/recordatorios/mis-recordatorios (recordatorios_store.py:
/// get_recordatorios_paciente). Es la fila completa de la tabla SQL más
/// el campo calculado `proximo_disparo`.
library;

class Recordatorio {
  final int id;
  final String rutPaciente;
  final int? eventoId;
  final String tipo; // ej: "medicamento"
  final String descripcion; // nombre del medicamento/control
  final String? detalle; // ej: "Amoxicilina — 500mg"
  final DateTime fechaInicio;
  final int? frecuenciaHoras; // null = dosis única (control/indicación)
  final int? duracionDias;
  final DateTime? fechaFin;
  final bool activo;
  final bool editadoPorUsuario;
  final DateTime createdAt;
  final String creadoPor;

  /// Hora del próximo disparo NO enviado. Null si no quedan disparos
  /// pendientes (tratamiento terminado). Esto es lo que la UI debe
  /// mostrar como "próxima toma", nunca `fechaInicio` directamente.
  final DateTime? proximoDisparo;

  Recordatorio({
    required this.id,
    required this.rutPaciente,
    this.eventoId,
    required this.tipo,
    required this.descripcion,
    this.detalle,
    required this.fechaInicio,
    this.frecuenciaHoras,
    this.duracionDias,
    this.fechaFin,
    required this.activo,
    required this.editadoPorUsuario,
    required this.createdAt,
    required this.creadoPor,
    this.proximoDisparo,
  });

  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    DateTime? parseFecha(dynamic v) {
      if (v == null) return null;
      return DateTime.parse(v as String);
    }

    return Recordatorio(
      id: json['id'],
      rutPaciente: json['rut_paciente'] ?? '',
      eventoId: json['evento_id'],
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      detalle: json['detalle'],
      fechaInicio: parseFecha(json['fecha_inicio'])!,
      frecuenciaHoras: json['frecuencia_horas'],
      duracionDias: json['duracion_dias'],
      fechaFin: parseFecha(json['fecha_fin']),
      activo: json['activo'] ?? true,
      editadoPorUsuario: json['editado_por_usuario'] ?? false,
      createdAt: parseFecha(json['created_at'])!,
      creadoPor: json['creado_por'] ?? '',
      proximoDisparo: parseFecha(json['proximo_disparo']),
    );
  }

  /// Es un recordatorio recurrente (medicamento con frecuencia) vs.
  /// un disparo único (control, indicación puntual).
  bool get esRecurrente => frecuenciaHoras != null;

  /// Nombre a mostrar en pantalla: prioriza `detalle` (incluye dosis) si existe.
  String get textoMostrar => (detalle != null && detalle!.isNotEmpty) ? detalle! : descripcion;
}

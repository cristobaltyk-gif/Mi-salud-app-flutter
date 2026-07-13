/// lib/models/recordatorio.dart
///
/// Representa una fila de la tabla `recordatorios`, tal como la retorna
/// GET /api/recordatorios/mis-recordatorios (recordatorios_store.py:
/// get_recordatorios_paciente). Es la fila completa de la tabla SQL más
/// el campo calculado `proximo_disparo`.
///
/// v1.1 — FIX: parseFecha() ahora llama .toLocal() después de
/// DateTime.parse(). Antes, un string con offset UTC (como los que
/// manda el backend) se parseaba a un DateTime marcado como UTC, pero
/// nunca se convertía a hora local — la pantalla de recordatorios
/// imprimía directamente los valores UTC como si fueran locales, sin
/// restar ni sumar nada. Como Chile está en UTC-4/-3, esto desplazaba
/// cada horario mostrado varias horas hacia adelante (y a veces al día
/// siguiente), haciendo que recordatorios cercanos parecieran estar
/// muy lejos en el tiempo.
///
/// v1.2 — /mis-recordatorios ahora fusiona los recordatorios propios
/// con los de cada paciente que esta cuenta cuide (recordatorios_router.py).
/// Se agregan esPropio y pacienteNombre para que la UI pueda diferenciar
/// de quién es cada recordatorio. Ambos son opcionales/con default: si
/// el backend no los manda (respuestas más antiguas, u otros endpoints
/// que reusan este modelo, como generarDesdeEvento), esPropio asume
/// true y pacienteNombre queda null — comportamiento idéntico al de
/// antes de este cambio.
library;
class Recordatorio {
  final int id;
  final String rutPaciente;
  final int? eventoId;
  final String tipo;
  final String descripcion;
  final String? detalle;
  final DateTime fechaInicio;
  final int? frecuenciaHoras;
  final int? duracionDias;
  final DateTime? fechaFin;
  final bool activo;
  final bool editadoPorUsuario;
  final DateTime createdAt;
  final String creadoPor;
  final DateTime? proximoDisparo;
  final bool esPropio;
  final String? pacienteNombre;
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
    this.esPropio = true,
    this.pacienteNombre,
  });
  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    DateTime? parseFecha(dynamic v) {
      if (v == null) return null;
      return DateTime.parse(v as String).toLocal();
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
      esPropio: json['es_propio'] ?? true,
      pacienteNombre: json['paciente_nombre'],
    );
  }
  bool get esRecurrente => frecuenciaHoras != null;
  String get textoMostrar =>
      (detalle != null && detalle!.isNotEmpty) ? detalle! : descripcion;
  /// Serializa a JSON para guardar en storage local.
  /// Permite reprogramar alarmas sin token ni conexión.
  Map<String, dynamic> toJson() => {
    'id': id,
    'rut_paciente': rutPaciente,
    'evento_id': eventoId,
    'tipo': tipo,
    'descripcion': descripcion,
    'detalle': detalle,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'frecuencia_horas': frecuenciaHoras,
    'duracion_dias': duracionDias,
    'fecha_fin': fechaFin?.toIso8601String(),
    'activo': activo,
    'editado_por_usuario': editadoPorUsuario,
    'created_at': createdAt.toIso8601String(),
    'creado_por': creadoPor,
    'proximo_disparo': proximoDisparo?.toIso8601String(),
    'es_propio': esPropio,
    'paciente_nombre': pacienteNombre,
  };
}

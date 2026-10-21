/// lib/models/evento_clinico.dart
///
/// v1.1: especialidad y cantidad de fotos por atención, campos de
/// odontología (examen bucal, piezas tratadas, plan de tratamiento) y
/// paginación del resumen (hayMas + conMasEventos) — el backend entrega
/// las atenciones de a 20.
library;

import 'paciente.dart';

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

/// Un medicamento individual dentro de medicamentos_estructurados (no
/// confundir con "receta", que es el texto libre -- ver ContenidoEvento).
/// Mismos campos que lee recordatorios_router.py en el backend.
class MedicamentoEstructurado {
  final String medicamento;
  final String? dosis;
  final int? frecuenciaHoras;
  final int? duracionDias;

  MedicamentoEstructurado({
    required this.medicamento,
    this.dosis,
    this.frecuenciaHoras,
    this.duracionDias,
  });

  factory MedicamentoEstructurado.fromJson(Map<String, dynamic> json) {
    return MedicamentoEstructurado(
      medicamento: json['medicamento'] ?? '',
      dosis: json['dosis'],
      frecuenciaHoras: json['frecuencia_horas'],
      duracionDias: json['duracion_dias'],
    );
  }
}

/// Texto de un campo que puede venir como texto o como mapa (ej. el
/// odontograma {"1.6": "caries"}, que el backend ya convierte a texto).
String textoDeCampo(dynamic valor) {
  if (valor == null) return '';
  if (valor is String) return valor;
  if (valor is Map) {
    return valor.entries
        .where((e) => (e.value?.toString() ?? '').trim().isNotEmpty)
        .map((e) => 'Pieza ${e.key}: ${e.value}')
        .join('\n');
  }
  return valor.toString();
}

class ContenidoEvento {
  final String atencion;
  final String diagnostico;
  final String indicaciones;
  final String receta;
  final String ordenKinesiologia;
  final String indicacionQuirurgica;
  final String examenes;
  final String examenClinicoBucal;
  final String piezasTratadas;
  final String planTratamiento;
  final int? fotosCount;
  final List<FotoEvento> fotosDermatologia;
  final List<MedicamentoEstructurado> medicamentosEstructurados;

  ContenidoEvento({
    this.atencion = '',
    this.diagnostico = '',
    this.indicaciones = '',
    this.receta = '',
    this.ordenKinesiologia = '',
    this.indicacionQuirurgica = '',
    this.examenes = '',
    this.examenClinicoBucal = '',
    this.piezasTratadas = '',
    this.planTratamiento = '',
    this.fotosCount,
    this.fotosDermatologia = const [],
    this.medicamentosEstructurados = const [],
  });

  factory ContenidoEvento.fromJson(Map<String, dynamic> json) {
    return ContenidoEvento(
      atencion: json['atencion'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      indicaciones: json['indicaciones'] ?? '',
      receta: json['receta'] ?? '',
      ordenKinesiologia: json['orden_kinesiologia'] ?? '',
      indicacionQuirurgica: json['indicacion_quirurgica'] ?? '',
      examenes: json['examenes'] ?? '',
      examenClinicoBucal: textoDeCampo(json['examen_clinico_bucal']),
      piezasTratadas: textoDeCampo(json['piezas_tratadas']),
      planTratamiento: textoDeCampo(json['plan_tratamiento']),
      fotosCount: json['fotos_count'],
      fotosDermatologia: (json['fotos_dermatologia'] as List<dynamic>? ?? [])
          .map((f) => FotoEvento.fromJson(f as Map<String, dynamic>))
          .toList(),
      // Acepta ambas variantes de nombre, mismo fallback que ya usa
      // recordatorios_router.py en el backend (snake_case / camelCase
      // segun si el evento paso por la conversion FHIR o no).
      medicamentosEstructurados: (
        (json['medicamentos_estructurados'] ?? json['medicamentosEstructurados'])
                as List<dynamic>? ??
            []
      )
          .map((m) => MedicamentoEstructurado.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get tieneContenido =>
      atencion.isNotEmpty ||
      diagnostico.isNotEmpty ||
      indicaciones.isNotEmpty ||
      receta.isNotEmpty ||
      ordenKinesiologia.isNotEmpty ||
      indicacionQuirurgica.isNotEmpty ||
      examenes.isNotEmpty ||
      examenClinicoBucal.isNotEmpty ||
      piezasTratadas.isNotEmpty ||
      planTratamiento.isNotEmpty ||
      fotosDermatologia.isNotEmpty;

  bool get tieneMedicamentosParaCotizar => medicamentosEstructurados.isNotEmpty;
}

class EventoClinico {
  final int id;
  final String fecha;
  final String tipo;
  final String medico;
  final String diagnostico;
  final String especialidad;
  final int fotosCount;
  final ContenidoEvento contenido;

  EventoClinico({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.medico,
    required this.diagnostico,
    this.especialidad = '',
    this.fotosCount = 0,
    required this.contenido,
  });

  factory EventoClinico.fromJson(Map<String, dynamic> json) {
    return EventoClinico(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? 'consulta',
      medico: json['medico'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      especialidad: json['especialidad'] ?? '',
      fotosCount: json['fotos_count'] ?? 0,
      contenido: ContenidoEvento.fromJson(
        json['contenido'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class FichaResumen {
  final Paciente paciente;
  final int totalConsultas;
  final String? ultimaConsulta;
  final Map<String, dynamic> antecedentes;
  final List<EventoClinico> eventos;
  final bool hayMas;

  FichaResumen({
    required this.paciente,
    required this.totalConsultas,
    this.ultimaConsulta,
    required this.antecedentes,
    required this.eventos,
    this.hayMas = false,
  });

  /// Este resumen con las atenciones de la página siguiente agregadas al final.
  FichaResumen conMasEventos(FichaResumen siguiente) {
    return FichaResumen(
      paciente: paciente,
      totalConsultas: totalConsultas,
      ultimaConsulta: ultimaConsulta,
      antecedentes: antecedentes,
      eventos: [...eventos, ...siguiente.eventos],
      hayMas: siguiente.hayMas,
    );
  }

  factory FichaResumen.fromJson(Map<String, dynamic> json) {
    return FichaResumen(
      paciente: Paciente.fromMe(json['paciente'] as Map<String, dynamic>),
      totalConsultas: json['total_consultas'] ?? 0,
      ultimaConsulta: json['ultima_consulta'],
      antecedentes: json['antecedentes'] as Map<String, dynamic>? ?? {},
      eventos: (json['eventos'] as List<dynamic>? ?? [])
          .map((e) => EventoClinico.fromJson(e as Map<String, dynamic>))
          .toList(),
      hayMas: json['hay_mas'] == true,
    );
  }
}

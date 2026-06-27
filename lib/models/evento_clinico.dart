/// lib/models/evento_clinico.dart
///
/// Representa un evento/consulta clínica. Campos calzan exactamente con
/// el array `eventos` de GET /api/ficha/resumen (ficha_router.py v1.4).
library;

import 'paciente.dart';

class ContenidoEvento {
  final String atencion;
  final String diagnostico;
  final String indicaciones;
  final String receta;
  final String ordenKinesiologia;
  final String indicacionQuirurgica;
  final String examenes;
  final int? fotosCount;

  ContenidoEvento({
    this.atencion = '',
    this.diagnostico = '',
    this.indicaciones = '',
    this.receta = '',
    this.ordenKinesiologia = '',
    this.indicacionQuirurgica = '',
    this.examenes = '',
    this.fotosCount,
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
      fotosCount: json['fotos_count'],
    );
  }

  /// True si hay al menos un campo clínico con contenido.
  bool get tieneContenido =>
      atencion.isNotEmpty ||
      diagnostico.isNotEmpty ||
      indicaciones.isNotEmpty ||
      receta.isNotEmpty ||
      ordenKinesiologia.isNotEmpty ||
      indicacionQuirurgica.isNotEmpty ||
      examenes.isNotEmpty;
}

class EventoClinico {
  final int id;
  final String fecha; // formato YYYY-MM-DD (ya recortado por el backend)
  final String tipo;
  final String medico;
  final String diagnostico;
  final ContenidoEvento contenido;

  EventoClinico({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.medico,
    required this.diagnostico,
    required this.contenido,
  });

  factory EventoClinico.fromJson(Map<String, dynamic> json) {
    return EventoClinico(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? 'consulta',
      medico: json['medico'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      contenido: ContenidoEvento.fromJson(
        json['contenido'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Resultado completo de GET /api/ficha/resumen
class FichaResumen {
  final Paciente paciente;
  final int totalConsultas;
  final String? ultimaConsulta;
  final Map<String, dynamic> antecedentes;
  final List<EventoClinico> eventos;

  FichaResumen({
    required this.paciente,
    required this.totalConsultas,
    this.ultimaConsulta,
    required this.antecedentes,
    required this.eventos,
  });

  factory FichaResumen.fromJson(Map<String, dynamic> json) {
    return FichaResumen(
      paciente: Paciente.fromMe(json['paciente'] as Map<String, dynamic>),
      totalConsultas: json['total_consultas'] ?? 0,
      ultimaConsulta: json['ultima_consulta'],
      antecedentes: json['antecedentes'] as Map<String, dynamic>? ?? {},
      eventos: (json['eventos'] as List<dynamic>? ?? [])
          .map((e) => EventoClinico.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

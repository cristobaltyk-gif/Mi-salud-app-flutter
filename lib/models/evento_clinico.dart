/// lib/models/evento_clinico.dart
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

class ContenidoEvento {
  final String atencion;
  final String diagnostico;
  final String indicaciones;
  final String receta;
  final String ordenKinesiologia;
  final String indicacionQuirurgica;
  final String examenes;
  final int? fotosCount;
  final List<FotoEvento> fotosDermatologia;

  ContenidoEvento({
    this.atencion = '',
    this.diagnostico = '',
    this.indicaciones = '',
    this.receta = '',
    this.ordenKinesiologia = '',
    this.indicacionQuirurgica = '',
    this.examenes = '',
    this.fotosCount,
    this.fotosDermatologia = const [],
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
      fotosDermatologia: (json['fotos_dermatologia'] as List<dynamic>? ?? [])
          .map((f) => FotoEvento.fromJson(f as Map<String, dynamic>))
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
      fotosDermatologia.isNotEmpty;
}

class EventoClinico {
  final int id;
  final String fecha;
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

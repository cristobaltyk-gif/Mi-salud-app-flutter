/// lib/services/agenda_service.dart
///
/// "Agendar hora": centros que ofrecen atención a domicilio o presencial,
/// con sus profesionales (backend de ICA, público:
/// GET /api/servicios/centros?modalidad=domicilio|presencial).
/// La reserva en sí se hace en la página de reservas del centro (mismo
/// flujo que la web: horas reales, dirección, pago con el Flow del centro).
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Visita a domicilio del paciente (seguimiento tipo Uber, creado por Ficha Clínica).
class VisitaDomicilio {
  final String fecha;
  final String hora;
  final String profesional;
  final String direccion;
  final String estado; // confirmada | en_camino | en_domicilio
  final String? codigo;
  final int? etaSeg;
  final DateTime? etaAt;
  final String link;

  VisitaDomicilio({
    required this.fecha,
    required this.hora,
    required this.profesional,
    required this.direccion,
    required this.estado,
    this.codigo,
    this.etaSeg,
    this.etaAt,
    required this.link,
  });

  factory VisitaDomicilio.fromJson(Map<String, dynamic> json) {
    return VisitaDomicilio(
      fecha: json['fecha']?.toString() ?? '',
      hora: json['hora']?.toString() ?? '',
      profesional: json['profesional']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'confirmada',
      codigo: json['codigo']?.toString(),
      etaSeg: json['eta_seg'] is num ? (json['eta_seg'] as num).toInt() : null,
      etaAt: json['eta_at'] != null ? DateTime.tryParse(json['eta_at'].toString()) : null,
      link: json['link']?.toString() ?? '',
    );
  }

  /// Minutos que faltan según el último tiempo estimado (se va descontando).
  int? get minutosRestantes {
    if (etaSeg == null) return null;
    final pasado = etaAt == null ? 0 : DateTime.now().difference(etaAt!).inSeconds;
    final restante = etaSeg! - (pasado < 0 ? 0 : pasado);
    final min = (restante / 60).round();
    return min < 1 ? 1 : min;
  }
}

class ProfesionalAgenda {
  final String id;
  final String nombre;
  final String especialidad;
  final String rol;

  ProfesionalAgenda({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.rol,
  });

  factory ProfesionalAgenda.fromJson(Map<String, dynamic> json) {
    return ProfesionalAgenda(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      especialidad: json['especialidad']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
    );
  }

  /// Especialidad para mostrar (Odontología, Kinesiología, Traumatología…).
  String get etiqueta {
    final r = rol.toLowerCase();
    if (r == 'odontologo') return 'Odontología';
    if (r == 'kine') return 'Kinesiología';
    if (r == 'psicologo') return 'Psicología';
    if (r == 'enfermera') return 'Enfermería';
    final e = especialidad.toLowerCase();
    if (e.contains('dermat')) return 'Dermatología';
    if (e.contains('odont') || e.contains('implant') || e.contains('dental')) return 'Odontología';
    if (e.contains('kine')) return 'Kinesiología';
    if (e.contains('psico')) return 'Psicología';
    if (e.contains('enferm')) return 'Enfermería';
    const trauma = ['traumat', 'cadera', 'rodilla', 'hombro', 'columna', 'tobillo', 'mano', 'codo'];
    if (trauma.any((t) => e.contains(t))) return 'Traumatología';
    return especialidad;
  }
}

class CentroAgenda {
  final String id;
  final String nombre;
  final bool soloDomicilio;
  final String urlReservas;
  final List<ProfesionalAgenda> profesionales;

  CentroAgenda({
    required this.id,
    required this.nombre,
    required this.soloDomicilio,
    required this.urlReservas,
    required this.profesionales,
  });

  factory CentroAgenda.fromJson(Map<String, dynamic> json) {
    return CentroAgenda(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      soloDomicilio: json['solo_domicilio'] == true,
      urlReservas: json['url_reservas']?.toString() ?? '',
      profesionales: (json['profesionales'] as List<dynamic>? ?? [])
          .map((p) => ProfesionalAgenda.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Página de reservas del centro con el profesional ya elegido.
  Uri urlReservaDe(ProfesionalAgenda p) {
    return Uri.parse('$urlReservas/?modo=asistente&dr=${Uri.encodeQueryComponent(p.id)}');
  }
}

class AgendaService {
  /// Visitas a domicilio del paciente con sesión (MiSalud backend).
  static Future<List<VisitaDomicilio>> misVisitasDomicilio() async {
    final token = await StorageService.obtenerToken();
    if (token == null) return [];
    final res = await http.get(
      Uri.parse(AppConfig.fichaDomicilioEndpoint),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['visitas'] as List<dynamic>? ?? [])
        .map((v) => VisitaDomicilio.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CentroAgenda>> centros(String modalidad) async {
    final res = await http.get(Uri.parse(AppConfig.serviciosCentrosEndpoint(modalidad)));
    if (res.statusCode != 200) {
      throw Exception('No se pudieron cargar los centros (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['centros'] as List<dynamic>? ?? [])
        .map((c) => CentroAgenda.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

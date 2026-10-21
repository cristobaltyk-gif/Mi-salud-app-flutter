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
    final e = especialidad.toLowerCase();
    if (e.contains('dermat')) return 'Dermatología';
    if (e.contains('odont') || e.contains('implant') || e.contains('dental')) return 'Odontología';
    if (e.contains('kine')) return 'Kinesiología';
    if (e.contains('psico')) return 'Psicología';
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

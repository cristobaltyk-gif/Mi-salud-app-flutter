/// lib/services/agenda_service.dart
///
/// Citas del paciente (ver, cambiar de hora, cancelar) y "Agendar hora":
/// centros que ofrecen atención a domicilio o presencial,
/// con sus profesionales (backend de ICA, público:
/// GET /api/servicios/centros?modalidad=domicilio|presencial).
/// La reserva en sí se hace en la página de reservas del centro (mismo
/// flujo que la web: horas reales, dirección, pago con el Flow del centro).
library;

import 'dart:convert';
import 'http_sesion.dart' as http;
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

/// Hora agendada del paciente (o de la persona que cuida): presencial,
/// a domicilio o telemedicina. Backend de ICA: GET /api/paciente/citas.
class Cita {
  final String fecha; // YYYY-MM-DD
  final String hora;  // HH:MM
  final String professional; // id
  final String profesional;  // nombre para mostrar
  final String especialidad;
  final String centro;
  final String tipo; // presencial | domicilio | telemedicina
  final String estado; // reservada | confirmada | por_confirmar (efectivo, lo aprueba el centro)
  final String pago;   // domicilio: en_linea | efectivo | mensual
  final String direccion;
  final bool puedeCambiar;
  final bool puedeCancelar;
  final String motivo; // por qué no se puede cambiar/cancelar
  final bool pagoPendiente;
  final Map<String, dynamic>? seguimiento;

  Cita({
    required this.fecha,
    required this.hora,
    required this.professional,
    required this.profesional,
    required this.especialidad,
    required this.centro,
    required this.tipo,
    required this.estado,
    this.pago = '',
    required this.direccion,
    required this.puedeCambiar,
    required this.puedeCancelar,
    required this.motivo,
    required this.pagoPendiente,
    this.seguimiento,
  });

  factory Cita.fromJson(Map<String, dynamic> j) => Cita(
        fecha: j['fecha']?.toString() ?? '',
        hora: j['hora']?.toString() ?? '',
        professional: j['professional']?.toString() ?? '',
        profesional: j['profesional']?.toString() ?? '',
        especialidad: j['especialidad']?.toString() ?? '',
        centro: j['centro']?.toString() ?? '',
        tipo: j['tipo']?.toString() ?? 'presencial',
        estado: j['estado']?.toString() ?? 'reservada',
        pago: j['pago']?.toString() ?? '',
        direccion: j['direccion']?.toString() ?? '',
        puedeCambiar: j['puede_cambiar'] == true,
        puedeCancelar: j['puede_cancelar'] == true,
        motivo: j['motivo']?.toString() ?? '',
        pagoPendiente: j['pago_pendiente'] == true,
        seguimiento: j['seguimiento'] is Map<String, dynamic> ? j['seguimiento'] as Map<String, dynamic> : null,
      );

  /// Fecha legible: "sáb 24 oct".
  String get fechaCorta {
    final d = DateTime.tryParse(fecha);
    if (d == null) return fecha;
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';
  }

  String get tipoTexto => tipo == 'domicilio'
      ? '🏠 A domicilio'
      : tipo == 'telemedicina'
          ? '💻 Telemedicina'
          : '🏥 Presencial';

  /// Domicilio con seguimiento (código, mapa, tiempo de llegada).
  VisitaDomicilio? get visita {
    final s = seguimiento;
    if (tipo != 'domicilio' || s == null) return null;
    return VisitaDomicilio.fromJson({
      ...s,
      'fecha': fechaCorta,
      'hora': hora,
      'profesional': profesional,
      'direccion': direccion,
    });
  }
}

class ProfesionalAgenda {
  final String id;
  final String nombre;
  final String especialidad;
  final String rol;
  /// Distancia al paciente (presencial: a su lugar más cercano; domicilio: desde su base)
  final double? distanciaKm;
  /// Presencial: dónde atiende {nombre, direccion, lat, lng}
  final Map<String, dynamic>? lugar;

  ProfesionalAgenda({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.rol,
    this.distanciaKm,
    this.lugar,
  });

  factory ProfesionalAgenda.fromJson(Map<String, dynamic> json) {
    return ProfesionalAgenda(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      especialidad: json['especialidad']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
      distanciaKm: json['distancia_km'] is num ? (json['distancia_km'] as num).toDouble() : null,
      lugar: json['lugar'] is Map<String, dynamic> ? json['lugar'] as Map<String, dynamic> : null,
    );
  }

  String get kmTexto => distanciaKm == null ? '' : '${distanciaKm!.toStringAsFixed(1).replaceAll('.', ',')} km';

  /// Link "Cómo llegar" (Google Maps) al lugar de atención
  Uri? get comoLlegar {
    final l = lugar;
    if (l == null) return null;
    // Sin coordenadas, la dirección se busca en Chile ("Pirineos 123" no es España)
    final dir = (l['direccion'] ?? '').toString();
    final destino = l['lat'] != null
        ? '${l['lat']},${l['lng']}'
        : (dir.toLowerCase().trim().endsWith('chile') ? dir : '$dir, Chile');
    return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destino)}');
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
  /// Dermatología online: precio y link directo a la consulta online.
  final int? precio;
  final String? urlOnline;
  /// Distancia al paciente (el profesional más cercano del centro)
  final double? distanciaKm;

  CentroAgenda({
    required this.id,
    required this.nombre,
    required this.soloDomicilio,
    required this.urlReservas,
    required this.profesionales,
    this.precio,
    this.urlOnline,
    this.distanciaKm,
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
      precio: json['precio'] is num ? (json['precio'] as num).toInt() : null,
      distanciaKm: json['distancia_km'] is num ? (json['distancia_km'] as num).toDouble() : null,
      urlOnline: json['url_online']?.toString(),
    );
  }

  /// Página de reservas del centro con el profesional ya elegido; con
  /// modalidad, solo muestra horas de esa modalidad.
  Uri urlReservaDe(ProfesionalAgenda p, {String? modalidad}) {
    final m = modalidad == null ? '' : '&modalidad=${Uri.encodeQueryComponent(modalidad)}';
    return Uri.parse('$urlReservas/?modo=asistente&dr=${Uri.encodeQueryComponent(p.id)}$m');
  }
}

class AgendaService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String _error(http.Response res, String porDefecto) {
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map && d['detail'] is String) return d['detail'] as String;
    } catch (_) {}
    return porDefecto;
  }

  /// Próximas horas del paciente con sesión, o de la persona cuidada.
  static Future<List<Cita>> misCitas({String? rutPaciente}) async {
    final res = await http.get(Uri.parse(AppConfig.citasEndpoint(rutPaciente: rutPaciente)),
        headers: await _headers());
    if (res.statusCode != 200) throw Exception(_error(res, 'No se pudieron cargar tus horas'));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['citas'] as List<dynamic>? ?? [])
        .map((c) => Cita.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Horas libres del mismo profesional y tipo para un día (YYYY-MM-DD).
  static Future<List<String>> horasDisponibles(Cita cita, String fecha) async {
    final res = await http.get(
        Uri.parse(AppConfig.citasDisponiblesEndpoint(cita.professional, fecha, cita.tipo)),
        headers: await _headers());
    if (res.statusCode != 200) throw Exception(_error(res, 'No se pudieron cargar las horas'));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['horas'] as List<dynamic>? ?? []).map((h) => h.toString()).toList();
  }

  static Future<void> cancelar(Cita cita, {String? rutPaciente}) async {
    final res = await http.post(Uri.parse(AppConfig.citasCancelarEndpoint),
        headers: await _headers(),
        body: jsonEncode({
          'fecha': cita.fecha,
          'hora': cita.hora,
          'professional': cita.professional,
          if (rutPaciente != null) 'rut_paciente': rutPaciente,
        }));
    if (res.statusCode != 200) throw Exception(_error(res, 'No se pudo cancelar la hora'));
  }

  static Future<void> reprogramar(Cita cita, String nuevaFecha, String nuevaHora, {String? rutPaciente}) async {
    final res = await http.post(Uri.parse(AppConfig.citasReprogramarEndpoint),
        headers: await _headers(),
        body: jsonEncode({
          'fecha': cita.fecha,
          'hora': cita.hora,
          'professional': cita.professional,
          'nueva_fecha': nuevaFecha,
          'nueva_hora': nuevaHora,
          if (rutPaciente != null) 'rut_paciente': rutPaciente,
        }));
    if (res.statusCode != 200) throw Exception(_error(res, 'No se pudo cambiar la hora'));
  }

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

  /// direccion (opcional): la del paciente → ordenado por cercanía y, a
  /// domicilio, solo profesionales que llegan a esa dirección.
  static Future<List<CentroAgenda>> centros(String modalidad, {String? direccion}) async {
    var url = AppConfig.serviciosCentrosEndpoint(modalidad);
    if ((direccion ?? '').trim().length >= 4) {
      url += '&direccion=${Uri.encodeQueryComponent(direccion!.trim())}';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('No se pudieron cargar los centros (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['centros'] as List<dynamic>? ?? [])
        .map((c) => CentroAgenda.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

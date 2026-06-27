/// lib/services/recordatorios_service.dart
///
/// Cliente HTTP para recordatorios_router.py. No se incluye
/// POST /push/suscribir — ese endpoint es para el flujo Web Push del
/// frontend React (VAPID/Service Worker). La app Flutter no se suscribe
/// a push del servidor; programa notificaciones LOCALES en el propio
/// dispositivo a partir de los horarios que retorna este servicio
/// (ver alarm_service.dart).
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/recordatorio.dart';
import 'storage_service.dart';

class RecordatoriosException implements Exception {
  final String mensaje;
  RecordatoriosException(this.mensaje);
  @override
  String toString() => mensaje;
}

class RecordatoriosService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.obtenerToken();
    if (token == null) {
      throw RecordatoriosException('No hay sesión activa');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// GET /api/recordatorios/mis-recordatorios
  /// Retorna solo recordatorios vigentes (con al menos un disparo pendiente).
  static Future<List<Recordatorio>> misRecordatorios() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(AppConfig.recordatoriosMisRecordatoriosEndpoint),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw RecordatoriosException('No se pudieron cargar los recordatorios (${res.statusCode})');
    }

    final lista = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return lista.map((e) => Recordatorio.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/recordatorios/generar/{evento_id}
  /// Genera recordatorios a partir de una consulta clínica existente
  /// (solo funciona si ese evento tiene medicamentos_estructurados).
  static Future<List<Recordatorio>> generarDesdeEvento(int eventoId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse(AppConfig.recordatoriosGenerarEndpoint(eventoId)),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw RecordatoriosException('No se pudieron generar los recordatorios (${res.statusCode})');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final creados = body['creados'] as List<dynamic>;
    return creados.map((e) => Recordatorio.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// PATCH /api/recordatorios/{id}
  /// Edición única — el backend devuelve 409 si ya fue editado antes.
  static Future<Recordatorio> editar(
    int recordatorioId, {
    String? descripcion,
    DateTime? fechaInicio,
    int? frecuenciaHoras,
    int? duracionDias,
    bool? activo,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (descripcion != null) body['descripcion'] = descripcion;
    if (fechaInicio != null) body['fecha_inicio'] = fechaInicio.toIso8601String();
    if (frecuenciaHoras != null) body['frecuencia_horas'] = frecuenciaHoras;
    if (duracionDias != null) body['duracion_dias'] = duracionDias;
    if (activo != null) body['activo'] = activo;

    final res = await http.patch(
      Uri.parse(AppConfig.recordatorioEditarEndpoint(recordatorioId)),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 409) {
      throw RecordatoriosException(
        'Este recordatorio ya fue editado antes y no se puede modificar de nuevo',
      );
    }
    if (res.statusCode != 200) {
      throw RecordatoriosException('No se pudo editar el recordatorio (${res.statusCode})');
    }

    return Recordatorio.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }
}

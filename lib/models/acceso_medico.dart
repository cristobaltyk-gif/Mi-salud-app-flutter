/// lib/models/acceso_medico.dart
///
/// Representa un acceso temporal generado vía POST /api/compartir/generar
/// y listado vía GET /api/compartir/mis-links (ficha_compartida_router.py).
library;

enum EstadoAccesoMedico {
  pendiente,
  enUso,
  cerrado,
  expirado,
  revocado,
  invitacionExpirada,
  desconocido,
}

EstadoAccesoMedico _parsearEstado(String raw) {
  switch (raw) {
    case 'pendiente':
      return EstadoAccesoMedico.pendiente;
    case 'en_uso':
      return EstadoAccesoMedico.enUso;
    case 'cerrado':
      return EstadoAccesoMedico.cerrado;
    case 'expirado':
      return EstadoAccesoMedico.expirado;
    case 'revocado':
      return EstadoAccesoMedico.revocado;
    case 'invitacion_expirada':
      return EstadoAccesoMedico.invitacionExpirada;
    default:
      return EstadoAccesoMedico.desconocido;
  }
}

class AccesoMedico {
  final int id;
  final String? medicoRut;
  final String token;
  final EstadoAccesoMedico estado;
  final DateTime creadoAt;
  final DateTime expiraInvitacion;
  final DateTime? usadoAt;
  final DateTime? expiraSesion;

  AccesoMedico({
    required this.id,
    this.medicoRut,
    required this.token,
    required this.estado,
    required this.creadoAt,
    required this.expiraInvitacion,
    this.usadoAt,
    this.expiraSesion,
  });

  factory AccesoMedico.fromJson(Map<String, dynamic> json) {
    DateTime? parseFecha(dynamic v) => v == null ? null : DateTime.parse(v as String);

    return AccesoMedico(
      id: json['id'],
      medicoRut: json['medico_rut'],
      token: json['token'] ?? '',
      estado: _parsearEstado(json['estado'] ?? ''),
      creadoAt: parseFecha(json['creado_at'])!,
      expiraInvitacion: parseFecha(json['expira_invitacion'])!,
      usadoAt: parseFecha(json['usado_at']),
      expiraSesion: parseFecha(json['expira_sesion']),
    );
  }

  bool get estaActivo =>
      estado == EstadoAccesoMedico.pendiente || estado == EstadoAccesoMedico.enUso;

  String get etiqueta {
    switch (estado) {
      case EstadoAccesoMedico.pendiente:
        return 'Esperando médico';
      case EstadoAccesoMedico.enUso:
        return 'En uso ahora';
      case EstadoAccesoMedico.cerrado:
        return 'Sesión cerrada';
      case EstadoAccesoMedico.expirado:
      case EstadoAccesoMedico.invitacionExpirada:
        return 'Expirado';
      case EstadoAccesoMedico.revocado:
        return 'Revocado';
      case EstadoAccesoMedico.desconocido:
        return 'Desconocido';
    }
  }
}

class LinkGenerado {
  final String token;
  final DateTime expiraInvitacion;
  final int duracionSesionHrs;

  LinkGenerado({
    required this.token,
    required this.expiraInvitacion,
    required this.duracionSesionHrs,
  });

  factory LinkGenerado.fromJson(Map<String, dynamic> json) {
    return LinkGenerado(
      token: json['token'] ?? '',
      expiraInvitacion: DateTime.parse(json['expira_invitacion']),
      duracionSesionHrs: json['duracion_sesion_hrs'] ?? 3,
    );
  }
}

/// lib/models/cuidador.dart
///
/// Modelos para el sistema de vínculo cuidador-paciente (cuidador_router.py
/// v1.2). Cubre tanto el lado "paciente que invita" como "cuidador que
/// escanea y ve a quién cuida".
library;

/// Catálogo de niveles de acceso — GET /api/cuidador/niveles-acceso
class NivelAcceso {
  final String valor; // "medicamentos" | "indicaciones" | "completo"
  final String descripcion;

  NivelAcceso({required this.valor, required this.descripcion});

  factory NivelAcceso.fromJson(Map<String, dynamic> json) {
    return NivelAcceso(
      valor: json['valor'] ?? '',
      descripcion: json['descripcion'] ?? '',
    );
  }
}

/// Resultado de POST /api/cuidador/invitar — el QR recién generado.
class InvitacionGenerada {
  final int id;
  final String token; // este valor es el que se codifica en el QR
  final DateTime expiraInvitacion;
  final String textoConsentimiento;

  InvitacionGenerada({
    required this.id,
    required this.token,
    required this.expiraInvitacion,
    required this.textoConsentimiento,
  });

  factory InvitacionGenerada.fromJson(Map<String, dynamic> json) {
    return InvitacionGenerada(
      id: json['id'],
      token: json['token'] ?? '',
      expiraInvitacion: DateTime.parse(json['expira_invitacion']),
      textoConsentimiento: json['texto_consentimiento'] ?? '',
    );
  }
}

/// Item de la lista GET /api/cuidador/mis-invitaciones
/// (estado puede ser: pendiente | vinculado | expirado | revocado)
class InvitacionCuidador {
  final int id;
  final String cuidadorNombre;
  final String cuidadorApellidos;
  final String cuidadorRut;
  final String? relacion;
  final String nivelAcceso;
  final String estado;
  final DateTime creadoAt;

  InvitacionCuidador({
    required this.id,
    required this.cuidadorNombre,
    required this.cuidadorApellidos,
    required this.cuidadorRut,
    this.relacion,
    required this.nivelAcceso,
    required this.estado,
    required this.creadoAt,
  });

  factory InvitacionCuidador.fromJson(Map<String, dynamic> json) {
    return InvitacionCuidador(
      id: json['id'],
      cuidadorNombre: json['cuidador_nombre'] ?? '',
      cuidadorApellidos: json['cuidador_apellidos'] ?? '',
      cuidadorRut: json['cuidador_rut'] ?? '',
      relacion: json['relacion'],
      nivelAcceso: json['nivel_acceso'] ?? '',
      estado: json['estado'] ?? '',
      creadoAt: DateTime.parse(json['creado_at']),
    );
  }

  String get nombreCompleto => '$cuidadorNombre $cuidadorApellidos'.trim();
}

/// Item de la lista GET /api/cuidador/mis-cuidados
/// (pacientes que este usuario cuida, vista desde el lado del cuidador)
class PacienteCuidado {
  final int vinculoId;
  final String rutPaciente;
  final String? relacion;
  final String nivelAcceso;
  final DateTime confirmadoEn;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;

  PacienteCuidado({
    required this.vinculoId,
    required this.rutPaciente,
    this.relacion,
    required this.nivelAcceso,
    required this.confirmadoEn,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
  });

  factory PacienteCuidado.fromJson(Map<String, dynamic> json) {
    return PacienteCuidado(
      vinculoId: json['id'],
      rutPaciente: json['rut_paciente'] ?? '',
      relacion: json['relacion'],
      nivelAcceso: json['nivel_acceso'] ?? '',
      confirmadoEn: DateTime.parse(json['confirmado_en']),
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellido_paterno'] ?? '',
      apellidoMaterno: json['apellido_materno'],
    );
  }

  String get nombreCompleto =>
      '$nombre $apellidoPaterno${(apellidoMaterno?.isNotEmpty ?? false) ? ' $apellidoMaterno' : ''}'.trim();
}

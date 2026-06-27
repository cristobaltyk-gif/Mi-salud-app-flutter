/// lib/models/paciente.dart
///
/// Representa al paciente logueado. Campos calzan exactamente con lo que
/// retornan GET /api/auth/me y POST /api/auth/buscar (auth_router.py v1.5).
library;

class Paciente {
  final String rut;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String? email;
  final String? fechaNacimiento;
  final String? prevision;

  Paciente({
    required this.rut,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno = '',
    this.email,
    this.fechaNacimiento,
    this.prevision,
  });

  /// Construye desde la respuesta de GET /api/auth/me
  factory Paciente.fromMe(Map<String, dynamic> json) {
    return Paciente(
      rut: json['rut'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellido_paterno'] ?? '',
      apellidoMaterno: json['apellido_materno'] ?? '',
      email: json['email'],
      fechaNacimiento: json['fecha_nacimiento'],
      prevision: json['prevision'],
    );
  }

  /// Construye desde la respuesta de POST /api/auth/login
  /// (login.py retorna solo: token, rut, nombre, apellido — campos limitados)
  factory Paciente.fromLogin(Map<String, dynamic> json) {
    return Paciente(
      rut: json['rut'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellido'] ?? '',
    );
  }

  String get nombreCompleto =>
      '$nombre $apellidoPaterno${apellidoMaterno.isNotEmpty ? ' $apellidoMaterno' : ''}'.trim();
}

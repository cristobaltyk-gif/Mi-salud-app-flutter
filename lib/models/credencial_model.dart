/// lib/models/credencial_model.dart
/// Modelo para Credenciales Verificables W3C

class CredencialVerificable {
  final String id;
  final String tipo; // "diagnostico", "medicamento", "alergia"
  final Map<String, dynamic> credencial; // VC W3C completo
  final DateTime emitida;
  final DateTime? expira;
  final bool almacenadoLocalmente;

  CredencialVerificable({
    required this.id,
    required this.tipo,
    required this.credencial,
    required this.emitida,
    this.expira,
    this.almacenadoLocalmente = false,
  });

  factory CredencialVerificable.fromJson(Map<String, dynamic> json) {
    return CredencialVerificable(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? '',
      credencial: json['credencial'] ?? {},
      emitida: DateTime.parse(json['emitida'] ?? DateTime.now().toIso8601String()),
      expira: json['expira'] != null ? DateTime.parse(json['expira']) : null,
      almacenadoLocalmente: json['almacenadoLocalmente'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'credencial': credencial,
    'emitida': emitida.toIso8601String(),
    'expira': expira?.toIso8601String(),
    'almacenadoLocalmente': almacenadoLocalmente,
  };

  bool get esValida {
    if (expira == null) return true;
    return DateTime.now().isBefore(expira!);
  }

  String get tipoDisplay {
    switch (tipo) {
      case 'diagnostico':
        return 'Diagnóstico';
      case 'medicamento':
        return 'Medicamento';
      case 'alergia':
        return 'Alergia';
      default:
        return tipo;
    }
  }

  String get descripcion {
    final subject = credencial['credentialSubject'] ?? {};
    switch (tipo) {
      case 'diagnostico':
        return subject['diagnosis'] ?? 'Sin diagnóstico';
      case 'medicamento':
        return '${subject['medication'] ?? 'Medicamento'} - ${subject['dosage'] ?? ''}';
      case 'alergia':
        return '${subject['allergen'] ?? 'Alergia'} (${subject['severity'] ?? 'desconocida'})';
      default:
        return 'Credencial';
    }
  }
}

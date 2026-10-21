/// lib/widgets/etiqueta_especialidad.dart
///
/// Etiqueta de especialidad (🦷 Odontología, 🧴 Dermatología…) para las
/// atenciones de la ficha y los profesionales de "Agendar hora". Mismos
/// colores que MiSalud web (fichaCompartido.jsx).
library;

import 'package:flutter/material.dart';

class EtiquetaEspecialidad extends StatelessWidget {
  final String especialidad;
  const EtiquetaEspecialidad({super.key, required this.especialidad});

  static const Map<String, (String, Color, Color)> _estilos = {
    'Traumatología': ('🦴', Color(0xFF1D4ED8), Color(0xFFEFF6FF)),
    'Dermatología': ('🧴', Color(0xFFBE185D), Color(0xFFFDF2F8)),
    'Odontología': ('🦷', Color(0xFF0E7490), Color(0xFFECFEFF)),
    'Kinesiología': ('🏃', Color(0xFF15803D), Color(0xFFF0FDF4)),
    'Psicología': ('🧠', Color(0xFF7C3AED), Color(0xFFF5F3FF)),
  };

  @override
  Widget build(BuildContext context) {
    if (especialidad.isEmpty) return const SizedBox.shrink();
    final estilo = _estilos[especialidad] ?? ('🩺', const Color(0xFF475569), const Color(0xFFF1F5F9));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: estilo.$3,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${estilo.$1} $especialidad',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: estilo.$2),
      ),
    );
  }
}

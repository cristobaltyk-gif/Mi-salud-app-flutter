/// lib/screens/autorizar_tab_cuidado.dart
///
/// Pestaña "Autorizar médico" de FichaCuidadoScreen. Antes era una
/// tarjeta apretada arriba del listado principal; ahora tiene su
/// propio espacio y archivo, solo visible cuando el nivel de acceso es
/// completo (ver _tabsPara en ficha_cuidado_screen.dart).
library;

import 'package:flutter/material.dart';
import 'compartir_ficha_cuidado_screen.dart';

class TabAutorizarCuidado extends StatelessWidget {
  final String rutPaciente;
  const TabAutorizarCuidado({super.key, required this.rutPaciente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4C1D95).withOpacity(0.3)),
          ),
          child: const Icon(Icons.lock_outline, color: Color(0xFF4C1D95), size: 32),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('Autorizar acceso a médico',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.purple[800])),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Genera un acceso temporal para que un médico revise esta ficha',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.purple[300]),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C1D95)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: rutPaciente),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Generar acceso'),
          ),
        ),
      ],
    );
  }
}

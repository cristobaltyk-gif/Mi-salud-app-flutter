/// lib/widgets/estado_vacio.dart
///
/// Widget compartido: mensaje centrado para listas vacías. Usado por
/// ficha_tab_cuidado.dart y recordatorios_tab_cuidado.dart (antes
/// estaba duplicado como clase privada en ficha_cuidado_screen.dart).
library;

import 'package:flutter/material.dart';

class EstadoVacio extends StatelessWidget {
  final String texto;
  const EstadoVacio({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(texto, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
      ),
    );
  }
}

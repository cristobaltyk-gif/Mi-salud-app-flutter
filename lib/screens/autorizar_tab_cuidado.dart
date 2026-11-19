/// lib/screens/autorizar_tab_cuidado.dart
///
/// Pestaña "Autorizar médico" de FichaCuidadoScreen. Antes era una
/// tarjeta apretada arriba del listado principal; ahora tiene su
/// propio espacio y archivo, solo visible cuando el nivel de acceso es
/// completo (ver _tabsPara en ficha_cuidado_screen.dart).
///
/// v1.2: un solo botón "Autorizar médico". La app detecta la conexión: con
/// internet abre el acceso por enlace de siempre; sin internet, la consulta
/// sin conexión (consulta_sin_conexion_screen, Android).
library;

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'compartir_ficha_cuidado_screen.dart';
import 'consulta_sin_conexion_screen.dart';
import '../services/http_sesion.dart' as http;

class TabAutorizarCuidado extends StatelessWidget {
  final String rutPaciente;
  final bool esPropia;
  const TabAutorizarCuidado({super.key, required this.rutPaciente, this.esPropia = false});

  /// Un solo botón: con internet, el acceso por enlace de siempre; sin
  /// internet, la consulta sin conexión (Android). La app decide sola.
  Future<void> _autorizar(BuildContext context) async {
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final conRed = await http.hayInternet();
    navegador.pop();
    if (conRed) {
      navegador.push(MaterialPageRoute(
        builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: rutPaciente),
      ));
    } else if (Platform.isAndroid) {
      navegador.push(MaterialPageRoute(
        builder: (_) => ConsultaSinConexionScreen(rutPaciente: rutPaciente, esPropia: esPropia),
      ));
    } else {
      avisos.showSnackBar(const SnackBar(
        content: Text('Sin conexión a internet. Para autorizar a un médico necesitas red.'),
      ));
    }
  }

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
            'Da acceso temporal a un médico para que revise esta ficha',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.purple[300]),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C1D95)),
          onPressed: () => _autorizar(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Autorizar médico'),
          ),
        ),
      ],
    );
  }
}

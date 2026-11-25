/// lib/screens/autorizar_tab_cuidado.dart
///
/// Pestaña "Autorizar médico" de FichaCuidadoScreen. Antes era una
/// tarjeta apretada arriba del listado principal; ahora tiene su
/// propio espacio y archivo, solo visible cuando el nivel de acceso es
/// completo (ver _tabsPara en ficha_cuidado_screen.dart).
///
/// v1.2: un solo botón "Autorizar médico". La app detecta la conexión: con
/// internet abre el acceso por enlace de siempre; sin internet, la consulta
/// sin conexión con el Lector HypokratIA (lector_screen.dart).
///
/// v1.3: siempre abre el Lector primero (con o sin internet). Si en 15 s no
/// aparece un lector, la misma pantalla pasa sola al QR (con internet) o
/// avisa que se necesita el lector (sin internet). El paciente no elige.
library;

import 'package:flutter/material.dart';
import '../i18n/idioma.dart';
import 'lector_screen.dart';

class TabAutorizarCuidado extends StatelessWidget {
  final String rutPaciente;
  final bool esPropia;
  const TabAutorizarCuidado({super.key, required this.rutPaciente, this.esPropia = false});

  /// Un solo botón: con internet, el acceso por enlace de siempre; sin
  /// internet, la consulta sin conexión (Android). La app decide sola.
  Future<void> _autorizar(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LectorScreen(rutPaciente: rutPaciente, esPropia: esPropia),
    ));
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
          child: Text(tr('Autorizar acceso a médico'),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.purple[800])),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            tr('Da acceso temporal a un médico para que revise esta ficha'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.purple[300]),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C1D95)),
          onPressed: () => _autorizar(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(tr('Autorizar médico')),
          ),
        ),
      ],
    );
  }
}

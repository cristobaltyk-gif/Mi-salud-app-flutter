/// lib/screens/seleccion_idioma_screen.dart
///
/// Primera apertura de la app: "¿En qué idioma quieres usar MiSalud?".
/// Se elige UNA vez (el idioma del país donde la persona vive y se atiende)
/// y queda guardado. Viene marcado el idioma del teléfono.
library;

import 'package:flutter/material.dart';

import '../i18n/idioma.dart';

class SeleccionIdiomaScreen extends StatefulWidget {
  final VoidCallback alElegir;
  const SeleccionIdiomaScreen({super.key, required this.alElegir});

  @override
  State<SeleccionIdiomaScreen> createState() => _SeleccionIdiomaScreenState();
}

class _SeleccionIdiomaScreenState extends State<SeleccionIdiomaScreen> {
  late String _elegido = Idioma.actual.value;
  bool _guardando = false;

  void _marcar(String codigo) {
    setState(() => _elegido = codigo);
    Idioma.probar(codigo); // la pantalla se ve en ese idioma mientras elige
  }

  Future<void> _continuar() async {
    setState(() => _guardando = true);
    await Idioma.elegir(_elegido);
    widget.alElegir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/images/hypokratia_icon.png', width: 64, height: 64),
              ),
              const SizedBox(height: 20),
              Text(
                tr('¿En qué idioma quieres usar MiSalud?'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A3B8C)),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Elige el idioma del país donde vives y te atiendes. Tu ficha se muestra en el idioma en que la escribieron tus médicos.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              for (final e in Idioma.disponibles.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: _elegido == e.key ? const Color(0xFFE0E7FF) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _guardando ? null : () => _marcar(e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _elegido == e.key ? const Color(0xFF1A3B8C) : const Color(0xFFE2E8F0),
                            width: _elegido == e.key ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            ),
                            if (_elegido == e.key) const Icon(Icons.check_circle, color: Color(0xFF1A3B8C)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3B8C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _guardando ? null : _continuar,
                child: Text(tr('Continuar'), style: const TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

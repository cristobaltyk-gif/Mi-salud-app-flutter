/// lib/widgets/firma_terminos.dart
///
/// Pantalla para aceptar los Términos de uso del Portal. No se puede cerrar
/// sin aceptar: devuelve true si los aceptó, false si eligió "Salir".
library;

import 'package:flutter/material.dart';
import '../services/contratos_service.dart';

/// Párrafos separados por línea en blanco, **negrita** y viñetas "- ".
List<Widget> textoContrato(String texto) {
  final bloques = texto.trim().split(RegExp(r'\n\s*\n'));
  return bloques.map((b) {
    final spans = <InlineSpan>[];
    final lineas = b.split('\n');
    for (var i = 0; i < lineas.length; i++) {
      var t = lineas[i].trim();
      if (t.startsWith('- ')) t = '   • ${t.substring(2)}';
      final partes = t.split(RegExp(r'(\*\*[^*]+\*\*)'));
      final marcas = RegExp(r'\*\*([^*]+)\*\*').allMatches(t).map((m) => m.group(1)!).toList();
      for (var j = 0; j < partes.length; j++) {
        spans.add(TextSpan(text: partes[j]));
        if (j < marcas.length) spans.add(TextSpan(text: marcas[j], style: const TextStyle(fontWeight: FontWeight.w700)));
      }
      if (i < lineas.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(TextSpan(children: spans), style: const TextStyle(fontSize: 14, height: 1.45)),
    );
  }).toList();
}

Future<bool> pedirFirmaTerminos(BuildContext context, ContratoPendiente doc) async {
  final r = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _FirmaTerminos(doc: doc),
  ));
  return r ?? false;
}

class _FirmaTerminos extends StatefulWidget {
  final ContratoPendiente doc;
  const _FirmaTerminos({required this.doc});
  @override
  State<_FirmaTerminos> createState() => _FirmaTerminosState();
}

class _FirmaTerminosState extends State<_FirmaTerminos> {
  bool _acepto = false;
  bool _enviando = false;
  String? _error;

  Future<void> _aceptar() async {
    setState(() { _enviando = true; _error = null; });
    try {
      await ContratosService.aceptar(widget.doc);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text(doc.titulo, style: const TextStyle(fontSize: 17))),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '${doc.version > 1 ? 'Actualizamos los términos. ' : ''}Léelos y acéptalos para seguir usando el Portal. Te enviaremos una copia por correo.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: textoContrato(doc.texto)),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _acepto,
                      onChanged: (v) => setState(() => _acepto = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Leí y acepto los Términos de uso.', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    Row(
                      children: [
                        TextButton(onPressed: _enviando ? null : () => Navigator.of(context).pop(false), child: const Text('Salir')),
                        const Spacer(),
                        FilledButton(
                          onPressed: _acepto && !_enviando ? _aceptar : null,
                          child: Text(_enviando ? 'Guardando…' : 'Acepto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// lib/screens/evento_detalle_screen.dart
///
/// Detalle de una consulta clínica puntual. Muestra los campos reales que
/// retorna GET /api/ficha/resumen para el `contenido` de cada evento, y
/// permite pedir una explicación de ESA consulta en particular vía
/// GET /api/ficha/evento/{id} (streaming SSE).
library;

import 'package:flutter/material.dart';
import '../models/evento_clinico.dart';
import '../services/ficha_service.dart';

class EventoDetalleScreen extends StatelessWidget {
  final EventoClinico evento;

  const EventoDetalleScreen({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final contenido = evento.contenido;

    return Scaffold(
      appBar: AppBar(title: Text(evento.fecha)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          evento.medico.isNotEmpty ? evento.medico : 'Profesional no especificado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Tipo de consulta: ${evento.tipo}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _abrirExplicacion(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Explícame esta consulta en simple'),
          ),
          const SizedBox(height: 16),
          if (contenido.diagnostico.isNotEmpty)
            _SeccionDetalle(titulo: 'Diagnóstico', texto: contenido.diagnostico, icono: Icons.assignment_outlined),
          if (contenido.atencion.isNotEmpty)
            _SeccionDetalle(titulo: 'Atención', texto: contenido.atencion, icono: Icons.notes_outlined),
          if (contenido.indicaciones.isNotEmpty)
            _SeccionDetalle(titulo: 'Indicaciones', texto: contenido.indicaciones, icono: Icons.checklist_outlined),
          if (contenido.receta.isNotEmpty)
            _SeccionDetalle(titulo: 'Receta', texto: contenido.receta, icono: Icons.medication_outlined),
          if (contenido.ordenKinesiologia.isNotEmpty)
            _SeccionDetalle(
              titulo: 'Orden de kinesiología',
              texto: contenido.ordenKinesiologia,
              icono: Icons.accessibility_new_outlined,
            ),
          if (contenido.indicacionQuirurgica.isNotEmpty)
            _SeccionDetalle(
              titulo: 'Indicación quirúrgica',
              texto: contenido.indicacionQuirurgica,
              icono: Icons.healing_outlined,
            ),
          if (contenido.examenes.isNotEmpty)
            _SeccionDetalle(titulo: 'Exámenes', texto: contenido.examenes, icono: Icons.science_outlined),
          if (!contenido.tieneContenido)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Esta consulta no tiene detalle adicional registrado',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _abrirExplicacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExplicacionEventoSheet(eventoId: evento.id),
    );
  }
}

class _SeccionDetalle extends StatelessWidget {
  final String titulo;
  final String texto;
  final IconData icono;

  const _SeccionDetalle({required this.titulo, required this.texto, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 20, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(titulo, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// Misma lógica de streaming que la hoja de Ficha general, pero apuntando
/// al endpoint de un evento específico.
class _ExplicacionEventoSheet extends StatefulWidget {
  final int eventoId;
  const _ExplicacionEventoSheet({required this.eventoId});

  @override
  State<_ExplicacionEventoSheet> createState() => _ExplicacionEventoSheetState();
}

class _ExplicacionEventoSheetState extends State<_ExplicacionEventoSheet> {
  final StringBuffer _texto = StringBuffer();
  String? _error;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    FichaService.explicarEvento(widget.eventoId).listen(
      (evento) {
        if (!mounted) return;
        setState(() {
          switch (evento) {
            case ExplicacionTexto(texto: final t):
              _texto.write(t);
            case ExplicacionError(mensaje: final m):
              _error = m;
            case ExplicacionDone():
              _terminado = true;
          }
        });
      },
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text('Esta consulta, en simple', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(_texto.toString(), style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                ),
              if (!_terminado && _error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }
}

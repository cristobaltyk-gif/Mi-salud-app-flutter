/// lib/screens/evento_detalle_screen.dart
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
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
                  Text('Tipo de consulta: ${evento.tipo}',
                      style: TextStyle(color: Colors.grey[600])),
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
            _SeccionDetalle(titulo: 'Diagnóstico', texto: contenido.diagnostico,
                icono: Icons.assignment_outlined, eventoId: evento.id, tipoPdf: null),
          if (contenido.receta.isNotEmpty)
            _SeccionDetalle(titulo: 'Receta', texto: contenido.receta,
                icono: Icons.medication_outlined, eventoId: evento.id, tipoPdf: 'receta'),
          if (contenido.indicaciones.isNotEmpty)
            _SeccionDetalle(titulo: 'Indicaciones', texto: contenido.indicaciones,
                icono: Icons.checklist_outlined, eventoId: evento.id, tipoPdf: 'informe'),
          if (contenido.examenes.isNotEmpty)
            _SeccionDetalle(titulo: 'Exámenes', texto: contenido.examenes,
                icono: Icons.science_outlined, eventoId: evento.id, tipoPdf: 'examenes'),
          if (contenido.ordenKinesiologia.isNotEmpty)
            _SeccionDetalle(titulo: 'Orden de kinesiología', texto: contenido.ordenKinesiologia,
                icono: Icons.accessibility_new_outlined, eventoId: evento.id, tipoPdf: 'kinesiologia'),
          if (contenido.indicacionQuirurgica.isNotEmpty)
            _SeccionDetalle(titulo: 'Indicación quirúrgica', texto: contenido.indicacionQuirurgica,
                icono: Icons.healing_outlined, eventoId: evento.id, tipoPdf: 'quirurgica'),
          if (contenido.fotosDermatologia.isNotEmpty)
            _GaleriaFotos(fotos: contenido.fotosDermatologia),
          if (!contenido.tieneContenido)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Esta consulta no tiene detalle adicional registrado',
                  style: TextStyle(color: Colors.grey[600]))),
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

class _SeccionDetalle extends StatefulWidget {
  final String titulo;
  final String texto;
  final IconData icono;
  final int eventoId;
  final String? tipoPdf;

  const _SeccionDetalle({
    required this.titulo, required this.texto, required this.icono,
    required this.eventoId, required this.tipoPdf,
  });

  @override
  State<_SeccionDetalle> createState() => _SeccionDetalleState();
}

class _SeccionDetalleState extends State<_SeccionDetalle> {
  bool _descargando = false;

  Future<void> _descargarYAbrir() async {
    setState(() => _descargando = true);
    try {
      final ruta = await FichaService.descargarPdf(widget.eventoId, widget.tipoPdf!);
      await OpenFile.open(ruta);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el PDF: $e')));
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

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
                Icon(widget.icono, size: 20, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                if (widget.tipoPdf != null)
                  TextButton.icon(
                    onPressed: _descargando ? null : _descargarYAbrir,
                    icon: _descargando
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download_outlined, size: 16),
                    label: const Text('PDF'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.texto, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _GaleriaFotos extends StatefulWidget {
  final List<FotoEvento> fotos;
  const _GaleriaFotos({required this.fotos});

  @override
  State<_GaleriaFotos> createState() => _GaleriaFotosState();
}

class _GaleriaFotosState extends State<_GaleriaFotos> {
  FotoEvento? _ampliada;

  Uint8List _decode(String data) =>
      Uri.parse('data:image/jpeg;base64,$data').data!.contentAsBytes();

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
                const Icon(Icons.photo_library_outlined, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text('📸 Fotos (${widget.fotos.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.fotos.map((f) => GestureDetector(
                onTap: () => setState(() => _ampliada = f),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(_decode(f.data), width: 72, height: 72, fit: BoxFit.cover),
                ),
              )).toList(),
            ),
            if (_ampliada != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _ampliada = null),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_decode(_ampliada!.data),
                      width: double.infinity, fit: BoxFit.contain),
                ),
              ),
              if (_ampliada!.comentario.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_ampliada!.comentario,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5EEAD4))),
              ],
              TextButton(
                onPressed: () => setState(() => _ampliada = null),
                child: const Text('Cerrar foto'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
            case ExplicacionTexto(texto: final t): _texto.write(t);
            case ExplicacionError(mensaje: final m): _error = m;
            case ExplicacionDone(): _terminado = true;
          }
        });
      },
      onError: (e) { if (mounted) setState(() => _error = e.toString()); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55, maxChildSize: 0.9, minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text('Esta consulta, en simple', style: Theme.of(context).textTheme.titleMedium),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(_texto.toString(), style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: TextStyle(color: Colors.red[700]))),
              if (!_terminado && _error == null)
                const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}

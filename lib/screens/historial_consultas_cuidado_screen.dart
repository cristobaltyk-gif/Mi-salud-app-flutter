/// lib/screens/historial_consultas_cuidado_screen.dart
///
/// Historial completo de consultas de un paciente cuidado. Antes vivía
/// apilado dentro de la pestaña "Ficha" de ficha_cuidado_screen.dart —
/// si el paciente tenía muchas consultas, la primera pantalla quedaba
/// obnubilada por un listado enorme. Ahora es su propia pantalla,
/// alcanzable desde una tarjeta-link en la pestaña Ficha (mismo patrón
/// que "Mi ficha clínica" en dashboard_screen.dart / ficha_screen.dart).
///
/// _EventoCard, _MiniFoto, _decodeBase64 y _ExplicacionEventoCuidadoSheet
/// se mudaron acá tal cual desde ficha_cuidado_screen.dart — sin cambios
/// de comportamiento, solo de ubicación.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/ficha_cuidado.dart';
import '../services/ficha_service.dart';

class HistorialConsultasCuidadoScreen extends StatelessWidget {
  final String rutPaciente;
  final String nombrePaciente;
  final List<EventoCuidadoCompleto> eventos;

  const HistorialConsultasCuidadoScreen({
    super.key,
    required this.rutPaciente,
    required this.nombrePaciente,
    required this.eventos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Historial de consultas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(nombrePaciente, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: eventos.isEmpty
          ? Center(
              child: Text('Sin consultas registradas', style: TextStyle(color: Colors.grey[500])),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: eventos.map((ev) => _EventoCard(ev: ev, rutPaciente: rutPaciente)).toList(),
            ),
    );
  }
}

/// Tarjeta de evento clínico completo: detalle expandible,
/// descarga/apertura de PDF, galería de fotos.
class _EventoCard extends StatefulWidget {
  final EventoCuidadoCompleto ev;
  final String rutPaciente;
  const _EventoCard({required this.ev, required this.rutPaciente});

  @override
  State<_EventoCard> createState() => _EventoCardState();
}

class _EventoCardState extends State<_EventoCard> {
  bool _expandido = false;
  String? _descargando; // tipo de PDF actualmente descargando, o null

  static const _camposDetalle = [
    ('diagnostico', 'Diagnóstico', null),
    ('indicaciones', 'Indicaciones', 'informe'),
    ('receta', 'Receta', 'receta'),
    ('examenes', 'Exámenes', 'examenes'),
    ('ordenKinesiologia', 'Orden kinésica', 'kinesiologia'),
    ('indicacionQuirurgica', 'Indicación quirúrgica', 'quirurgica'),
  ];

  String _valorCampo(String key) {
    switch (key) {
      case 'diagnostico': return widget.ev.diagnostico;
      case 'indicaciones': return widget.ev.indicaciones;
      case 'receta': return widget.ev.receta;
      case 'examenes': return widget.ev.examenes;
      case 'ordenKinesiologia': return widget.ev.ordenKinesiologia;
      case 'indicacionQuirurgica': return widget.ev.indicacionQuirurgica;
      default: return '';
    }
  }

  Future<void> _descargarYAbrir(String tipoPdf) async {
    setState(() => _descargando = tipoPdf);
    try {
      final ruta = await FichaService.descargarPdf(
        widget.ev.id,
        tipoPdf,
        rutPaciente: widget.rutPaciente,
      );
      await OpenFile.open(ruta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _descargando = null);
    }
  }

  void _abrirExplicar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExplicacionEventoCuidadoSheet(
        eventoId: widget.ev.id,
        rutPaciente: widget.rutPaciente,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.ev.tipo.isNotEmpty
                      ? '${widget.ev.tipo[0].toUpperCase()}${widget.ev.tipo.substring(1)}'
                      : 'Consulta',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF134E4A)),
                ),
                Text(
                  widget.ev.fecha,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5EEAD4)),
                ),
              ],
            ),
            if (widget.ev.medico.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('👨‍⚕️ ${widget.ev.medico}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
            ],
            if (widget.ev.diagnostico.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Diagnóstico: ', style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.w600)),
                    TextSpan(text: widget.ev.diagnostico, style: const TextStyle(color: Color(0xFF134E4A))),
                  ]),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (widget.ev.tieneDetalle)
                  OutlinedButton(
                    onPressed: () => setState(() => _expandido = !_expandido),
                    child: Text(_expandido ? 'Ocultar' : 'Ver detalle'),
                  ),
                OutlinedButton(
                  onPressed: _abrirExplicar,
                  child: const Text('✨ Explicar'),
                ),
              ],
            ),
            if (_expandido) ...[
              const Divider(height: 20),
              for (final (key, label, pdfTipo) in _camposDetalle)
                if (_valorCampo(key).trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold,
                                color: Color(0xFF5EEAD4), letterSpacing: 1.0,
                              ),
                            ),
                            if (pdfTipo != null)
                              TextButton(
                                onPressed: _descargando == pdfTipo ? null : () => _descargarYAbrir(pdfTipo),
                                child: Text(_descargando == pdfTipo ? '...' : '⬇ PDF'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_valorCampo(key), style: const TextStyle(fontSize: 13, color: Color(0xFF134E4A), height: 1.5)),
                      ],
                    ),
                  ),
              if (widget.ev.fotosDermatologia.isNotEmpty) ...[
                Text(
                  '📸 Fotos (${widget.ev.fotosDermatologia.length})',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5EEAD4)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.ev.fotosDermatologia.map((f) => _MiniFoto(foto: f)).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniFoto extends StatelessWidget {
  final FotoEvento foto;
  const _MiniFoto({required this.foto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  child: Image.memory(_decodeBase64(foto.data)),
                ),
                if (foto.comentario.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(foto.comentario, style: const TextStyle(color: Color(0xFF99F6E4))),
                  ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _decodeBase64(foto.data),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ignore: unused_element
Uint8List _decodeBase64(String data) {
  return Uri.parse('data:image/jpeg;base64,$data').data!.contentAsBytes();
}

/// Mismo patrón que _ExplicacionEventoSheet en evento_detalle_screen.dart
/// (bottom sheet + streaming SSE inline) — aquí con rutPaciente, para que
/// el backend valide el vínculo de cuidador antes de generar la explicación.
class _ExplicacionEventoCuidadoSheet extends StatefulWidget {
  final int eventoId;
  final String rutPaciente;
  const _ExplicacionEventoCuidadoSheet({required this.eventoId, required this.rutPaciente});

  @override
  State<_ExplicacionEventoCuidadoSheet> createState() => _ExplicacionEventoCuidadoSheetState();
}

class _ExplicacionEventoCuidadoSheetState extends State<_ExplicacionEventoCuidadoSheet> {
  final StringBuffer _texto = StringBuffer();
  String? _error;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    FichaService.explicarEvento(widget.eventoId, rutPaciente: widget.rutPaciente).listen(
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
                  const Icon(Icons.auto_awesome, color: Color(0xFF0F766E)),
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

/// lib/screens/ficha_cuidado_screen.dart
///
/// Vista de la ficha de un paciente cuidado. El RUT llega como argumento
/// de navegación (no desde storage), igual que en la web.
///
/// v1.1: nivel "completo" ahora usa _EventoCard con detalle expandible,
/// descarga/apertura de PDF (open_file), y galería de fotos — igual
/// funcionalidad que EventoCard en Ficha.jsx / FichaCuidado.jsx de la
/// web. Antes solo mostraba un ListTile plano (diagnóstico + fecha).
///
/// v1.2 — Antes todo (antecedentes, recordatorios, historial, autorizar
/// médico) se apilaba en un solo ListView largo, mezclado. Ahora la
/// pantalla tiene una barra de pestañas abajo, igual estilo que
/// dashboard_screen.dart: "Ficha" (antecedentes/indicaciones/historial
/// según nivel de acceso), "Recordatorios" (medicamentos y controles,
/// como listado propio) y "Autorizar médico" (solo si el nivel es
/// completo). Cada pestaña es un listado simple y de un solo propósito,
/// en vez de secciones apiladas.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/ficha_cuidado.dart';
import '../models/recordatorio.dart';
import '../services/ficha_service.dart';
import 'compartir_ficha_cuidado_screen.dart';

class FichaCuidadoScreen extends StatefulWidget {
  final String rutPaciente;

  const FichaCuidadoScreen({super.key, required this.rutPaciente});

  @override
  State<FichaCuidadoScreen> createState() => _FichaCuidadoScreenState();
}

class _TabInfo {
  final IconData icono;
  final IconData iconoActivo;
  final String label;
  const _TabInfo({required this.icono, required this.iconoActivo, required this.label});
}

class _FichaCuidadoScreenState extends State<FichaCuidadoScreen> {
  Future<FichaCuidado>? _futureFicha;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _tabActual = 0;
      _futureFicha = FichaService.obtenerFichaCuidado(widget.rutPaciente);
    });
  }

  List<_TabInfo> _tabsPara(FichaCuidado ficha) {
    return [
      const _TabInfo(icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
      const _TabInfo(icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
      if (ficha.esCompleto)
        const _TabInfo(icono: Icons.lock_outline, iconoActivo: Icons.lock, label: 'Autorizar'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FichaCuidado>(
      future: _futureFicha,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const _BannerModoCuidador(nombrePaciente: null),
                  AppBar(
                    title: const Text('Ficha del paciente'),
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                            const SizedBox(height: 12),
                            Text('${snapshot.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ficha = snapshot.data!;
        final tabs = _tabsPara(ficha);
        final tabActual = _tabActual < tabs.length ? _tabActual : 0;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _BannerModoCuidador(nombrePaciente: ficha.paciente.nombreCompleto),
                AppBar(
                  title: Text(ficha.paciente.nombreCompleto),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                Expanded(
                  child: _buildTab(tabActual, ficha),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BarraInferior(
            tabs: tabs,
            tabActual: tabActual,
            onTap: (i) => setState(() => _tabActual = i),
          ),
        );
      },
    );
  }

  Widget _buildTab(int index, FichaCuidado ficha) {
    switch (index) {
      case 0:
        return _TabFicha(ficha: ficha, rutPaciente: widget.rutPaciente);
      case 1:
        return _TabRecordatorios(ficha: ficha);
      case 2:
        return _TabAutorizar(rutPaciente: widget.rutPaciente);
      default:
        return _TabFicha(ficha: ficha, rutPaciente: widget.rutPaciente);
    }
  }
}

class _BarraInferior extends StatelessWidget {
  final List<_TabInfo> tabs;
  final int tabActual;
  final ValueChanged<int> onTap;

  const _BarraInferior({required this.tabs, required this.tabActual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final activo = tabActual == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: activo ? const Color(0xFF0F766E).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activo ? tab.iconoActivo : tab.icono,
                        color: activo ? const Color(0xFF0F766E) : Colors.grey[500],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.normal,
                            color: activo ? const Color(0xFF0F766E) : Colors.grey[500],
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BannerModoCuidador extends StatelessWidget {
  final String? nombrePaciente;
  const _BannerModoCuidador({this.nombrePaciente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF4C1D95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Modo cuidador',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (nombrePaciente != null)
                    TextSpan(
                      text: ' · Viendo la ficha de $nombrePaciente',
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña "Ficha": contenido clínico según el nivel de acceso
/// autorizado. Ya no incluye recordatorios ni "Autorizar médico" —
/// ambos viven en sus propias pestañas.
class _TabFicha extends StatelessWidget {
  final FichaCuidado ficha;
  final String rutPaciente;
  const _TabFicha({required this.ficha, required this.rutPaciente});

  @override
  Widget build(BuildContext context) {
    if (ficha.esMedicamentos) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _EstadoVacio(texto: 'Este nivel de acceso solo autoriza ver medicamentos y controles.\nRevisa la pestaña "Recordatorios".'),
        ],
      );
    }

    if (ficha.esIndicaciones) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Acceso autorizado: indicaciones',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          if (ficha.eventosConIndicaciones.isEmpty)
            const _EstadoVacio(texto: 'Sin indicaciones registradas')
          else
            ...ficha.eventosConIndicaciones.map((ev) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.fecha, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(height: 6),
                        Text(ev.indicaciones, style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                )),
        ],
      );
    }

    if (ficha.esCompleto) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Acceso autorizado: completo',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),

          if (ficha.antecedentes != null) ...[
            Card(
              color: const Color(0xFFFFFDF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🏥', style: TextStyle(fontSize: 15)),
                        SizedBox(width: 8),
                        Text('Antecedentes médicos',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FilaAntecedente(
                      titulo: '⚠️ ALERGIAS',
                      colorTitulo: const Color(0xFFDC2626),
                      items: ficha.antecedentes!['alergia'] as List<dynamic>? ?? [],
                      vacio: 'Sin alergias conocidas',
                      colorFondo: const Color(0xFFFEF2F2),
                      colorTexto: const Color(0xFF991B1B),
                    ),
                    const SizedBox(height: 10),
                    _FilaAntecedente(
                      titulo: '💊 MEDICAMENTOS',
                      colorTitulo: const Color(0xFF1D4ED8),
                      items: ficha.antecedentes!['medicamento_habitual'] as List<dynamic>? ?? [],
                      vacio: 'Sin medicamentos habituales',
                      colorFondo: const Color(0xFFEFF6FF),
                      colorTexto: const Color(0xFF1E40AF),
                    ),
                    const SizedBox(height: 10),
                    _FilaAntecedente(
                      titulo: '🩺 CRÓNICAS',
                      colorTitulo: const Color(0xFF065F46),
                      items: ficha.antecedentes!['enfermedad_cronica'] as List<dynamic>? ?? [],
                      vacio: 'Sin enfermedades crónicas',
                      colorFondo: const Color(0xFFF0FDF4),
                      colorTexto: const Color(0xFF065F46),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text('Historial de consultas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (ficha.eventos.isEmpty)
            Text('Sin consultas registradas', style: TextStyle(color: Colors.grey[500]))
          else
            ...ficha.eventos.map((ev) => _EventoCard(ev: ev, rutPaciente: rutPaciente)),
        ],
      );
    }

    return const Center(child: Text('Nivel de acceso no reconocido'));
  }
}

/// Pestaña "Recordatorios": medicamentos y controles vigentes de este
/// paciente, como listado propio y simple.
class _TabRecordatorios extends StatelessWidget {
  final FichaCuidado ficha;
  const _TabRecordatorios({required this.ficha});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ficha.recordatorios.isEmpty)
          const _EstadoVacio(texto: 'Sin medicamentos ni controles vigentes')
        else
          ...ficha.recordatorios.map((r) => _TarjetaRecordatorio(r: r)),
      ],
    );
  }
}

/// Pestaña "Autorizar médico": antes era una tarjeta apretada arriba
/// del listado principal; ahora tiene su propio espacio, solo visible
/// cuando el nivel de acceso es completo (ver _tabsPara en el State).
class _TabAutorizar extends StatelessWidget {
  final String rutPaciente;
  const _TabAutorizar({required this.rutPaciente});

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

class _FilaAntecedente extends StatelessWidget {
  final String titulo;
  final Color colorTitulo;
  final List<dynamic> items;
  final String vacio;
  final Color colorFondo;
  final Color colorTexto;

  const _FilaAntecedente({
    required this.titulo,
    required this.colorTitulo,
    required this.items,
    required this.vacio,
    required this.colorFondo,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                letterSpacing: 0.8, color: colorTitulo)),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Text(vacio,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic)),
          )
        else
          ...items.map((it) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: colorFondo, borderRadius: BorderRadius.circular(8)),
                child: Text('${(it as Map)['descripcion'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: colorTexto, fontWeight: FontWeight.w500)),
              )),
      ],
    );
  }
}

/// Tarjeta de evento clínico completo: igual funcionalidad que
/// EventoCard en la web — detalle expandible, descarga/apertura de
/// PDF, galería de fotos.
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

class _TarjetaRecordatorio extends StatelessWidget {
  final Recordatorio r;
  const _TarjetaRecordatorio({required this.r});

  @override
  Widget build(BuildContext context) {
    final proxima = r.proximoDisparo != null
        ? DateFormat('EEE HH:mm', 'es').format(r.proximoDisparo!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.textoMostrar, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (proxima != null) ...[
              const SizedBox(height: 4),
              Text('⏰ Próxima toma: $proxima',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF14B8A6))),
            ],
            if (r.frecuenciaHoras != null) ...[
              const SizedBox(height: 2),
              Text(
                'Cada ${r.frecuenciaHoras}h${r.duracionDias != null ? ' · ${r.duracionDias} días de tratamiento' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String texto;
  const _EstadoVacio({required this.texto});

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

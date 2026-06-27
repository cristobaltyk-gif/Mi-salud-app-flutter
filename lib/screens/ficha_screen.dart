/// lib/screens/ficha_screen.dart
///
/// Muestra el resumen de la ficha (GET /api/ficha/resumen) y permite pedir
/// una explicación en lenguaje simple vía streaming SSE. Cada evento de la
/// lista lleva a EventoDetalleScreen para su propia explicación puntual.
library;

import 'package:flutter/material.dart';
import '../models/evento_clinico.dart';
import '../services/ficha_service.dart';
import 'evento_detalle_screen.dart';

class FichaScreen extends StatefulWidget {
  const FichaScreen({super.key});

  @override
  State<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends State<FichaScreen> {
  Future<FichaResumen>? _futureResumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() => _futureResumen = FichaService.obtenerResumen());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _cargar(),
      child: FutureBuilder<FichaResumen>(
        future: _futureResumen,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorConReintentar(
              mensaje: 'No se pudo cargar tu ficha: ${snapshot.error}',
              onReintentar: _cargar,
            );
          }

          final resumen = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumen.paciente.nombreCompleto,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resumen.totalConsultas} consultas registradas'
                        '${resumen.ultimaConsulta != null ? ' · última: ${resumen.ultimaConsulta}' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _abrirExplicacionGeneral(context),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Explícame mi historial en simple'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Historial de consultas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (resumen.eventos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aún no tienes consultas registradas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...resumen.eventos.map((ev) => _EventoCard(evento: ev)),
            ],
          );
        },
      ),
    );
  }

  void _abrirExplicacionGeneral(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExplicacionSheet(
        titulo: 'Tu historial, explicado simple',
        stream: FichaService.explicarFicha(),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final EventoClinico evento;
  const _EventoCard({required this.evento});

  IconData get _icono {
    switch (evento.tipo) {
      case 'control':
        return Icons.event_available_outlined;
      case 'cirugia':
        return Icons.medical_services_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icono, color: const Color(0xFF2563EB)),
        title: Text(
          evento.diagnostico.isNotEmpty ? evento.diagnostico : evento.tipo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${evento.fecha} · ${evento.medico}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventoDetalleScreen(evento: evento),
            ),
          );
        },
      ),
    );
  }
}

/// Hoja inferior que muestra el texto llegando en streaming SSE, palabra
/// por palabra, igual que se ve en la web. Reutilizable desde Ficha y
/// desde EventoDetalle.
class _ExplicacionSheet extends StatefulWidget {
  final String titulo;
  final Stream<ExplicacionEvento> stream;

  const _ExplicacionSheet({required this.titulo, required this.stream});

  @override
  State<_ExplicacionSheet> createState() => _ExplicacionSheetState();
}

class _ExplicacionSheetState extends State<_ExplicacionSheet> {
  final StringBuffer _texto = StringBuffer();
  String? _error;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
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
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
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
                  Expanded(
                    child: Text(widget.titulo, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    _texto.toString(),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
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

class _ErrorConReintentar extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorConReintentar({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

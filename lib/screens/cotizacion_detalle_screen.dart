/// lib/screens/cotizacion_detalle_screen.dart
library;

import 'package:flutter/material.dart';
import '../models/cotizacion.dart';
import '../models/evento_clinico.dart';
import '../services/cotizador_service.dart';

String _formatearCLP(int valor) {
  final texto = valor.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return '\$$buffer';
}

class CotizacionDetalleScreen extends StatefulWidget {
  final EventoClinico evento;
  const CotizacionDetalleScreen({super.key, required this.evento});

  @override
  State<CotizacionDetalleScreen> createState() => _CotizacionDetalleScreenState();
}

class _CotizacionDetalleScreenState extends State<CotizacionDetalleScreen> {
  Future<CotizacionResultado>? _futureResultado;

  @override
  void initState() {
    super.initState();
    _cotizar();
  }

  void _cotizar() {
    final items = widget.evento.contenido.medicamentosEstructurados
        .map((m) => ItemReceta(principioActivo: m.medicamento, presentacion: m.dosis))
        .toList();

    setState(() {
      _futureResultado = CotizadorService.cotizarReceta(items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.evento.diagnostico.isNotEmpty
              ? widget.evento.diagnostico
              : 'Cotización',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<CotizacionResultado>(
        future: _futureResultado,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cotizando en farmacias, un momento...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _cotizar, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }

          final resultado = snapshot.data!;
          final masBarata = resultado.farmaciaMasBarata;

          if (resultado.farmacias.isEmpty) {
            return const Center(child: Text('No hay farmacias disponibles.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...resultado.farmacias.map(
                (f) => _FarmaciaCard(farmacia: f, esMasBarata: f.farmacia == masBarata),
              ),
              const SizedBox(height: 8),
              Text(
                'Precios referenciales, sujetos a cambio en cada farmacia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 11.5),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _FarmaciaCard extends StatefulWidget {
  final FarmaciaCotizada farmacia;
  final bool esMasBarata;

  const _FarmaciaCard({required this.farmacia, required this.esMasBarata});

  @override
  State<_FarmaciaCard> createState() => _FarmaciaCardState();
}

class _FarmaciaCardState extends State<_FarmaciaCard> {
  String _nivel = 'economico';

  static const _labels = {
    'economico': 'Económico',
    'intermedio': 'Intermedio',
    'premium': 'Premium',
  };

  @override
  Widget build(BuildContext context) {
    final paquete = widget.farmacia.porNombre(_nivel);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.farmacia.farmacia,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3B8C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (widget.esMasBarata)
                            _Badge(
                              texto: 'Más económica',
                              color: const Color(0xFF0F766E),
                              fondo: const Color(0xFFF0FDF9),
                            ),
                          if (!widget.farmacia.completo)
                            _Badge(
                              texto: 'Receta incompleta',
                              color: Colors.red[700]!,
                              fondo: Colors.red[50]!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    Text(
                      _formatearCLP(paquete.total),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: _labels.entries
                  .map((e) => ButtonSegment(value: e.key, label: Text(e.value, style: const TextStyle(fontSize: 12.5))))
                  .toList(),
              selected: {_nivel},
              onSelectionChanged: (nuevo) => setState(() => _nivel = nuevo.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFF0F766E),
                selectedForegroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            ...paquete.items.map((item) => _ItemRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemCotizado item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.sinProducto) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '${item.principioActivo} — no disponible en este nivel',
          style: TextStyle(color: Colors.red[700], fontSize: 12.5),
        ),
      );
    }

    final p = item.producto!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombreComercial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.principioActivo} · ${p.laboratorio ?? "Laboratorio no informado"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            _formatearCLP(p.precioFinal),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;

  const _Badge({required this.texto, required this.color, required this.fondo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

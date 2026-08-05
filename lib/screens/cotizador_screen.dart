/// lib/screens/cotizador_screen.dart
library;

import 'package:flutter/material.dart';
import '../models/evento_clinico.dart';
import '../services/ficha_service.dart';
import 'cotizacion_detalle_screen.dart';

class CotizadorScreen extends StatefulWidget {
  const CotizadorScreen({super.key});

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  Future<FichaResumen>? _futureResumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureResumen = FichaService.obtenerResumen();
    });
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
              mensaje: 'No se pudieron cargar tus recetas: ${snapshot.error}',
              onReintentar: _cargar,
            );
          }

          final resumen = snapshot.data!;
          final recetas = resumen.eventos
              .where((ev) => ev.contenido.tieneMedicamentosParaCotizar)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '💊 Cotizador de medicamentos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E4A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Compara precios de tus recetas entre farmacias',
                style: TextStyle(color: const Color(0xFF0F766E), fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (recetas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no tienes recetas con medicamentos\npara cotizar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  'Recetas con medicamentos (${recetas.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...recetas.map((ev) => _RecetaCard(evento: ev)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecetaCard extends StatelessWidget {
  final EventoClinico evento;
  const _RecetaCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final cantidad = evento.contenido.medicamentosEstructurados.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF99F6E4)),
      ),
      child: ListTile(
        leading: const Text('💊', style: TextStyle(fontSize: 22)),
        title: Text(
          evento.diagnostico.isNotEmpty ? evento.diagnostico : 'Receta médica',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${evento.fecha}'
          '${evento.medico.isNotEmpty ? " · ${evento.medico}" : ""}'
          '\n$cantidad medicamento${cantidad != 1 ? "s" : ""} — Ver cotización',
          style: const TextStyle(color: Color(0xFF0F766E), fontSize: 12.5),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF0F766E)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CotizacionDetalleScreen(evento: evento),
          ),
        ),
      ),
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

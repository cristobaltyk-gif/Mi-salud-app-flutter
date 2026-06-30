/// lib/screens/recordatorios_screen.dart
///
/// Lista de recordatorios vigentes (GET /api/recordatorios/mis-recordatorios).
/// Esta es la pantalla que más le importa al paciente: qué medicamento,
/// qué dosis, y a qué hora es la próxima toma — que es exactamente
/// `proximoDisparo`, ya programado como alarma local por AlarmService
/// (ver dashboard_screen.dart, que llama a reprogramarTodas al sincronizar).
///
/// v1.1: FIX — las variables locales `mañana`/`esMañana` usaban la letra
/// ñ, que Dart no permite en identificadores (solo en strings y
/// comentarios). Renombradas a `manana`/`esManana` — el texto visible
/// para el usuario ('Mañana a las...') no cambia.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recordatorio.dart';
import '../services/recordatorios_service.dart';

class RecordatoriosScreen extends StatefulWidget {
  final Future<void> Function() onRecordatoriosCambiaron;

  const RecordatoriosScreen({super.key, required this.onRecordatoriosCambiaron});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  Future<List<Recordatorio>>? _futureRecordatorios;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() => _futureRecordatorios = RecordatoriosService.misRecordatorios());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _cargar(),
      child: FutureBuilder<List<Recordatorio>>(
        future: _futureRecordatorios,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
                    Text('No se pudieron cargar tus recordatorios:\n${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }

          final recordatorios = snapshot.data!;

          if (recordatorios.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 56, color: Colors.green[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No tienes recordatorios pendientes',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final ordenados = [...recordatorios]
            ..sort((a, b) {
              if (a.proximoDisparo == null) return 1;
              if (b.proximoDisparo == null) return -1;
              return a.proximoDisparo!.compareTo(b.proximoDisparo!);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenados.length,
            itemBuilder: (context, i) => _RecordatorioCard(recordatorio: ordenados[i]),
          );
        },
      ),
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  final Recordatorio recordatorio;
  const _RecordatorioCard({required this.recordatorio});

  String _formatearProximoDisparo() {
    final disparo = recordatorio.proximoDisparo;
    if (disparo == null) return 'Sin próxima toma';

    final ahora = DateTime.now();
    final esHoy = disparo.year == ahora.year && disparo.month == ahora.month && disparo.day == ahora.day;
    final manana = ahora.add(const Duration(days: 1));
    final esManana = disparo.year == manana.year && disparo.month == manana.month && disparo.day == manana.day;

    final hora = DateFormat('HH:mm').format(disparo);

    if (esHoy) return 'Hoy a las $hora';
    if (esManana) return 'Mañana a las $hora';
    return '${DateFormat('EEEE d MMM', 'es').format(disparo)} a las $hora';
  }

  @override
  Widget build(BuildContext context) {
    final urgente = recordatorio.proximoDisparo != null &&
        recordatorio.proximoDisparo!.difference(DateTime.now()).inHours < 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: urgente ? Colors.orange[50] : Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                recordatorio.esRecurrente ? Icons.medication_outlined : Icons.event_note_outlined,
                color: urgente ? Colors.orange[700] : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recordatorio.textoMostrar,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 14, color: urgente ? Colors.orange[700] : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatearProximoDisparo(),
                        style: TextStyle(
                          color: urgente ? Colors.orange[700] : Colors.grey[600],
                          fontWeight: urgente ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (recordatorio.esRecurrente) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cada ${recordatorio.frecuenciaHoras}h'
                      '${recordatorio.duracionDias != null ? ' · ${recordatorio.duracionDias} días de tratamiento' : ''}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

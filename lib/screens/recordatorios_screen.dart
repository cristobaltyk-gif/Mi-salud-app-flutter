/// lib/screens/recordatorios_screen.dart
///
/// v1.1 — /mis-recordatorios ahora fusiona los recordatorios propios
/// con los de cada paciente que esta cuenta cuide (recordatorios_router.py).
/// Se agrega un badge con el nombre del paciente en cada tarjeta cuando
/// el recordatorio no es propio (recordatorio.esPropio == false), para
/// no confundirlo con los propios. Color distinto al de urgencia
/// (morado, el mismo tono que usa "Modo cuidador" en ficha_cuidado_screen.dart),
/// para que ambas señales (urgencia vs. de quién es) no se pisen.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recordatorio.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';

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
    setState(() { _futureRecordatorios = _cargarYProgramar(); });
  }

  /// Trae los recordatorios del backend Y reprograma las alarmas
  /// locales del teléfono en el mismo paso. Antes esto solo pintaba
  /// la UI y nunca llamaba a AlarmService — por eso no sonaba nada.
  ///
  /// La lista que retorna el backend ya viene fusionada (propios +
  /// de pacientes cuidados), así que reprogramarTodas() programa
  /// ambos grupos de alarmas de una sola vez, sin distinción — los
  /// IDs de recordatorio son globales en la base, no chocan entre
  /// pacientes distintos.
  Future<List<Recordatorio>> _cargarYProgramar() async {
    final recordatorios = await RecordatoriosService.misRecordatorios();
    try {
      await AlarmService.reprogramarTodas(recordatorios);
    } catch (e) {
      // No queremos que un fallo al programar alarmas rompa la UI
      // que sí pudo cargar los recordatorios desde el backend.
      debugPrint('Error reprogramando alarmas: $e');
    }
    return recordatorios;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: () async => _cargar(),
      child: FutureBuilder<List<Recordatorio>>(
        future: _futureRecordatorios,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
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
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
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
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF99F6E4), width: 2),
                          ),
                          child: const Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Sin recordatorios pendientes',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF134E4A), fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Todo al día 👍', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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

          final urgentes = ordenados.where((r) =>
              r.proximoDisparo != null &&
              r.proximoDisparo!.difference(DateTime.now()).inHours < 2).toList();
          final resto = ordenados.where((r) =>
              r.proximoDisparo == null ||
              r.proximoDisparo!.difference(DateTime.now()).inHours >= 2).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (urgentes.isNotEmpty) ...[
                _SeccionHeader(icono: '⚡', titulo: 'Próximas 2 horas', color: Colors.orange[700]!),
                const SizedBox(height: 8),
                ...urgentes.map((r) => _RecordatorioCard(recordatorio: r)),
                const SizedBox(height: 16),
              ],
              if (resto.isNotEmpty) ...[
                _SeccionHeader(icono: '📅', titulo: 'Próximas tomas', color: const Color(0xFF0F766E)),
                const SizedBox(height: 8),
                ...resto.map((r) => _RecordatorioCard(recordatorio: r)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String icono;
  final String titulo;
  final Color color;
  const _SeccionHeader({required this.icono, required this.titulo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icono, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(titulo,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  final Recordatorio recordatorio;
  const _RecordatorioCard({required this.recordatorio});

  static const _colorCuidado = Color(0xFF6D28D9);
  static const _colorCuidadoFondo = Color(0xFFF5F3FF);

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
    final esCuidado = !recordatorio.esPropio && recordatorio.pacienteNombre != null;

    final colorPrincipal = urgente ? const Color(0xFFEA580C) : const Color(0xFF0F766E);
    final colorFondo = urgente ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF9);
    final colorBorde = urgente ? const Color(0xFFFED7AA) : const Color(0xFF99F6E4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: esCuidado ? _colorCuidado.withOpacity(0.4) : colorBorde,
            width: esCuidado ? 1.4 : 1),
        boxShadow: [
          BoxShadow(color: colorPrincipal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: colorPrincipal.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                recordatorio.esRecurrente ? Icons.medication_outlined : Icons.event_note_outlined,
                color: colorPrincipal, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (esCuidado) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _colorCuidadoFondo,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _colorCuidado.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 12, color: _colorCuidado),
                          const SizedBox(width: 4),
                          Text(
                            recordatorio.pacienteNombre!,
                            style: const TextStyle(
                              color: _colorCuidado, fontSize: 11, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(recordatorio.textoMostrar,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF134E4A))),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.alarm_outlined, size: 13, color: colorPrincipal),
                      const SizedBox(width: 4),
                      Text(_formatearProximoDisparo(),
                          style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  if (recordatorio.esRecurrente) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorPrincipal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cada ${recordatorio.frecuenciaHoras}h'
                        '${recordatorio.duracionDias != null ? ' · ${recordatorio.duracionDias} días' : ''}',
                        style: TextStyle(color: colorPrincipal, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (urgente)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('¡YA!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

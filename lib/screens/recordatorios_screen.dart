/// lib/screens/recordatorios_screen.dart
///
/// v1.1 — /mis-recordatorios ahora fusiona los recordatorios propios
/// con los de cada paciente que esta cuenta cuide (recordatorios_router.py).
/// Se agrega un badge con el nombre del paciente en cada tarjeta cuando
/// el recordatorio no es propio (recordatorio.esPropio == false), para
/// no confundirlo con los propios. Color distinto al de urgencia
/// (morado, el mismo tono que usa "Modo cuidador" en ficha_cuidado_screen.dart),
/// para que ambas señales (urgencia vs. de quién es) no se pisen.
///
/// v1.2 — Las tarjetas de recordatorios tipo 'ejercicio' (plan
/// domiciliario de kinesiología, con mediaPath no vacío) ahora son
/// tocables: al tocarlas, abren MediaEjercicioScreen con la misma foto
/// o video que se muestra al tocar la notificación — así el paciente
/// puede volver a verlo cuando quiera, sin depender de la notificación
/// (que ya pasó o se descartó). El resto de los tipos (medicamento,
/// control, indicación) no cambia: no tienen media, no se agrega nada
/// al tocarlos.
///
/// v1.3 — La separación propio/cuidado era muy tenue (solo el grosor
/// del borde cambiaba). Ahora:
///   - TODAS las tarjetas llevan badge, no solo las de cuidado: las
///     propias muestran "Tú" en teal; las de cuidado muestran el
///     nombre del paciente en morado. Misma posición siempre, cambia
///     color+texto — más fácil de distinguir de un vistazo.
///   - Las tarjetas de cuidado llevan tinte de fondo morado SIEMPRE,
///     independiente de si son urgentes o no (antes el fondo solo
///     dependía de la urgencia, ignorando de quién era). La urgencia
///     se sigue señalando por separado con el ícono/hora en naranja y
///     el badge "¡YA!", sin pisar la señal de "de quién es".
///
/// v1.4 — El badge de cuidado ahora incluye la relación
/// (recordatorio.pacienteRelacion, ej. "hija") cuando el backend la
/// trae: "Aurora · hija" en vez de solo "Aurora". Si no viene (null),
/// se muestra solo el nombre, igual que antes.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recordatorio.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import 'media_ejercicio_screen.dart';

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
  static const _colorCuidadoBorde = Color(0xFFDDD6FE);

  static const _colorPropio = Color(0xFF0F766E);
  static const _colorPropioFondoBadge = Color(0xFFE0F2F1);

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

  void _abrirMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaEjercicioScreen(
          titulo: recordatorio.descripcion,
          cuerpo: recordatorio.textoMostrar,
          mediaPath: recordatorio.mediaPath!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgente = recordatorio.proximoDisparo != null &&
        recordatorio.proximoDisparo!.difference(DateTime.now()).inHours < 2;
    final esCuidado = !recordatorio.esPropio && recordatorio.pacienteNombre != null;
    final tieneMedia = recordatorio.tipo == 'ejercicio' &&
        recordatorio.mediaPath != null &&
        recordatorio.mediaPath!.isNotEmpty;

    final tieneRelacion = esCuidado &&
        recordatorio.pacienteRelacion != null &&
        recordatorio.pacienteRelacion!.isNotEmpty;
    final textoBadge = esCuidado
        ? (tieneRelacion
            ? '${recordatorio.pacienteNombre} · ${recordatorio.pacienteRelacion}'
            : recordatorio.pacienteNombre!)
        : 'Tú';

    // La urgencia sigue marcándose en ícono/hora/badge "¡YA!" en
    // naranja, sea propio o de cuidado. El fondo/borde de la tarjeta
    // en cambio prioriza mostrar de quién es: si es de cuidado, el
    // tinte morado se mantiene fijo, no compite con el naranja de
    // urgencia — son dos señales distintas, no una sola.
    final colorPrincipal = urgente ? const Color(0xFFEA580C) : const Color(0xFF0F766E);
    final colorFondo = esCuidado
        ? _colorCuidadoFondo
        : (urgente ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF9));
    final colorBorde = esCuidado
        ? _colorCuidadoBorde
        : (urgente ? const Color(0xFFFED7AA) : const Color(0xFF99F6E4));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: esCuidado ? 1.6 : 1),
        boxShadow: [
          BoxShadow(color: colorPrincipal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tieneMedia ? () => _abrirMedia(context) : null,
          borderRadius: BorderRadius.circular(14),
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
                      // Badge siempre visible: "Tú" (teal) si es propio,
                      // "Nombre · relación" (morado) si es de cuidado
                      // (o solo "Nombre" si no hay relación declarada).
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: esCuidado ? _colorCuidadoFondo : _colorPropioFondoBadge,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (esCuidado ? _colorCuidado : _colorPropio).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              esCuidado ? Icons.people_outline : Icons.person_outline,
                              size: 12,
                              color: esCuidado ? _colorCuidado : _colorPropio,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              textoBadge,
                              style: TextStyle(
                                color: esCuidado ? _colorCuidado : _colorPropio,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
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
                if (tieneMedia)
                  Icon(Icons.play_circle_outline, color: colorPrincipal, size: 22),
                if (urgente)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
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
        ),
      ),
    );
  }
}

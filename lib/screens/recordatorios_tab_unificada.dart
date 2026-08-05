/// lib/screens/recordatorios_tab_unificada.dart
///
/// Tab "Recordatorios" del Dashboard con selector de carpetas.
/// A diferencia de Ficha/Cotizador/Autorizar, este tab SIEMPRE tiene
/// datos que mostrar sin importar el nivel de acceso (ver
/// CarpetaActiva.tieneAccesoRecordatorios) -- ficha_router.py incluye
/// recordatorios en los 3 niveles (medicamentos, indicaciones, completo).
///
/// Fuente de datos segun carpeta:
///   - Propia: RecordatoriosService.misRecordatorios() (ya viene
///     fusionado con las de cuidado) filtrado a esPropio == true, para
///     mostrar SOLO lo de esta persona -- antes ese mismo endpoint se
///     usaba sin filtrar (vista unificada); con el selector de carpetas,
///     cada carpeta debe mostrar solo lo suyo.
///   - Cuidado: FichaCuidado.recordatorios (ya viene filtrado a esa
///     persona especifica desde el backend, sin necesidad de filtrar
///     en el cliente).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/carpeta_activa.dart';
import '../models/ficha_cuidado.dart';
import '../models/recordatorio.dart';
import '../services/ficha_service.dart';
import '../services/recordatorios_service.dart';
import '../widgets/estado_vacio.dart';
import 'media_ejercicio_screen.dart';

class RecordatoriosTabUnificada extends StatefulWidget {
  final CarpetaActiva carpeta;
  const RecordatoriosTabUnificada({super.key, required this.carpeta});

  @override
  State<RecordatoriosTabUnificada> createState() => _RecordatoriosTabUnificadaState();
}

class _RecordatoriosTabUnificadaState extends State<RecordatoriosTabUnificada> {
  Future<List<Recordatorio>>? _future;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _future = widget.carpeta.esPropia ? _cargarPropios() : _cargarCuidado();
    });
  }

  Future<List<Recordatorio>> _cargarPropios() async {
    final todos = await RecordatoriosService.misRecordatorios();
    return todos.where((r) => r.esPropio).toList();
  }

  Future<List<Recordatorio>> _cargarCuidado() async {
    final FichaCuidado ficha = await FichaService.obtenerFichaCuidado(widget.carpeta.rutPaciente!);
    return ficha.recordatorios;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: () async => _cargar(),
      child: FutureBuilder<List<Recordatorio>>(
        future: _future,
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
                    Text('No se pudieron cargar los recordatorios:\n${snapshot.error}',
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
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: EstadoVacio(texto: 'Sin medicamentos ni controles vigentes'),
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
                ...urgentes.map((r) => _TarjetaRecordatorio(r: r)),
                const SizedBox(height: 16),
              ],
              if (resto.isNotEmpty) ...[
                _SeccionHeader(icono: '📅', titulo: 'Próximas tomas', color: const Color(0xFF0F766E)),
                const SizedBox(height: 8),
                ...resto.map((r) => _TarjetaRecordatorio(r: r)),
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

/// Version simplificada de la tarjeta -- ya no necesita badge de
/// "de quien es" (esPropio vs cuidado), porque cada carpeta ya muestra
/// solo lo suyo. La urgencia se sigue marcando en naranja igual que
/// antes.
class _TarjetaRecordatorio extends StatelessWidget {
  final Recordatorio r;
  const _TarjetaRecordatorio({required this.r});

  String _formatearProximoDisparo() {
    final disparo = r.proximoDisparo;
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
          titulo: r.descripcion,
          cuerpo: r.textoMostrar,
          mediaPath: r.mediaPath!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgente = r.proximoDisparo != null &&
        r.proximoDisparo!.difference(DateTime.now()).inHours < 2;
    final tieneMedia = r.tipo == 'ejercicio' && r.mediaPath != null && r.mediaPath!.isNotEmpty;
    final colorPrincipal = urgente ? const Color(0xFFEA580C) : const Color(0xFF0F766E);
    final colorFondo = urgente ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF9);
    final colorBorde = urgente ? const Color(0xFFFED7AA) : const Color(0xFF99F6E4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde),
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
                    r.esRecurrente ? Icons.medication_outlined : Icons.event_note_outlined,
                    color: colorPrincipal, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.textoMostrar,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF134E4A))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.alarm_outlined, size: 13, color: colorPrincipal),
                          const SizedBox(width: 4),
                          Text(_formatearProximoDisparo(),
                              style: TextStyle(color: colorPrincipal, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      if (r.esRecurrente) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorPrincipal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Cada ${r.frecuenciaHoras}h'
                            '${r.duracionDias != null ? ' · ${r.duracionDias} días' : ''}',
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

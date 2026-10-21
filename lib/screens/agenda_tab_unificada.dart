/// lib/screens/agenda_tab_unificada.dart
///
/// Pestaña "Agenda" (5° botón de abajo): agendar horas NUEVAS y administrar
/// las ya agendadas (cambiar de hora o cancelar). El seguimiento de las
/// citas (mapa, código, tiempo de llegada) vive en Recordatorios.
///
/// Funciona según la carpeta de arriba: en la propia, tus horas; en la de
/// una persona cuidada, las de ella (cualquier nivel de acceso: agendar no
/// expone la ficha clínica). Backend de ICA: /api/paciente/citas.
///
/// Reglas (las aplica el backend; aquí solo se muestran):
/// - Cambiar o cancelar: hasta 24 h antes. Después, llamando al centro.
/// - Cancelar: solo presenciales. Las pagadas en línea (domicilio,
///   telemedicina) solo se cambian de hora.
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';
import '../services/agenda_service.dart';
import '../widgets/tarjeta_visita_domicilio.dart';
import 'agendar_screen.dart';

const _azul = Color(0xFF1A3B8C);

class AgendaTabUnificada extends StatefulWidget {
  final CarpetaActiva carpeta;
  const AgendaTabUnificada({super.key, required this.carpeta});

  @override
  State<AgendaTabUnificada> createState() => _AgendaTabUnificadaState();
}

class _AgendaTabUnificadaState extends State<AgendaTabUnificada> {
  Future<List<Cita>>? _future;

  String? get _rut => widget.carpeta.esPropia ? null : widget.carpeta.rutPaciente;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final f = AgendaService.misCitas(rutPaciente: _rut);
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  void _agendar(String modalidad) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => AgendarScreen(
            modalidadInicial: modalidad,
            paraNombre: widget.carpeta.esPropia ? null : widget.carpeta.nombreMostrar,
          ),
        ))
        .then((_) => _cargar());
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cancelar(Cita cita) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar hora'),
        content: Text('¿Cancelar la hora del ${cita.fechaCorta} a las ${cita.hora} con ${cita.profesional}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar hora'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AgendaService.cancelar(cita, rutPaciente: _rut);
      _avisar('Hora cancelada. Te enviamos la confirmación por correo.');
    } catch (e) {
      _avisar(e.toString().replaceFirst('Exception: ', ''));
    }
    _cargar();
  }

  Future<void> _cambiar(Cita cita) async {
    final cambiada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _CambiarHora(cita: cita, rutPaciente: _rut),
    );
    if (cambiada == true) {
      _avisar('Hora cambiada. Te enviamos la confirmación por correo.');
      _cargar();
    }
  }

  Widget _acciones(Cita cita) {
    if (!cita.puedeCambiar && !cita.puedeCancelar) {
      return Text(cita.motivo, style: TextStyle(fontSize: 12.5, color: Colors.grey[600]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (cita.puedeCambiar)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cambiar(cita),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Cambiar hora'),
                ),
              ),
            if (cita.puedeCambiar && cita.puedeCancelar) const SizedBox(width: 8),
            if (cita.puedeCancelar)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
                  onPressed: () => _cancelar(cita),
                  icon: const Icon(Icons.event_busy_outlined, size: 18),
                  label: const Text('Cancelar'),
                ),
              ),
          ],
        ),
        if (cita.motivo.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(cita.motivo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final paraOtro = !widget.carpeta.esPropia;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(paraOtro ? 'Agendar hora para ${widget.carpeta.nombreMostrar}' : 'Agendar hora',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _azul)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _BotonNueva(
                icono: '🏠', titulo: 'A domicilio', sub: 'Te atienden en casa',
                onTap: () => _agendar('domicilio'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _BotonNueva(
                icono: '🏥', titulo: 'Presencial', sub: 'En un centro',
                onTap: () => _agendar('presencial'),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _BotonNueva(
                icono: '📱', titulo: 'Telemedicina', sub: 'Por videollamada',
                onTap: () => _agendar('telemedicina'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _BotonNueva(
                icono: '💻', titulo: 'Derma online', sub: 'Sin hora, con fotos',
                onTap: () => _agendar('online'),
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text(paraOtro ? 'Horas agendadas de ${widget.carpeta.nombreMostrar}' : 'Tus horas agendadas',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text('Puedes cambiarlas o cancelarlas hasta 24 horas antes.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
          const SizedBox(height: 10),
          FutureBuilder<List<Cita>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Column(
                  children: [
                    Text(snap.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                    TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                  ],
                );
              }
              final citas = snap.data ?? [];
              if (citas.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No hay horas agendadas.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                );
              }
              return Column(
                children: citas
                    .map((c) => TarjetaCita(cita: c, onActualizar: _cargar, acciones: _acciones(c)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BotonNueva extends StatelessWidget {
  final String icono;
  final String titulo;
  final String sub;
  final VoidCallback onTap;
  const _BotonNueva({required this.icono, required this.titulo, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icono, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: _azul)),
              Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegir día y hora nuevos (mismo profesional, mismo tipo de atención).
class _CambiarHora extends StatefulWidget {
  final Cita cita;
  final String? rutPaciente;
  const _CambiarHora({required this.cita, this.rutPaciente});

  @override
  State<_CambiarHora> createState() => _CambiarHoraState();
}

class _CambiarHoraState extends State<_CambiarHora> {
  static const _dias = 21;
  late final List<DateTime> _fechas;
  late DateTime _fecha;
  Future<List<String>>? _horas;
  String? _hora;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechas = List.generate(_dias, (i) => DateTime(hoy.year, hoy.month, hoy.day + i));
    _fecha = _fechas.first;
    _cargarHoras();
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _cargarHoras() {
    setState(() {
      _hora = null;
      _horas = AgendaService.horasDisponibles(widget.cita, _iso(_fecha));
    });
  }

  Future<void> _confirmar() async {
    if (_hora == null) return;
    setState(() { _guardando = true; _error = null; });
    try {
      await AgendaService.reprogramar(widget.cita, _iso(_fecha), _hora!, rutPaciente: widget.rutPaciente);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _guardando = false; _error = e.toString().replaceFirst('Exception: ', ''); });
      _cargarHoras();
    }
  }

  @override
  Widget build(BuildContext context) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cambiar hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('${widget.cita.profesional} · ${widget.cita.tipoTexto}',
                style: TextStyle(color: Colors.grey[700])),
            Text('Hora actual: ${widget.cita.fechaCorta} a las ${widget.cita.hora}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 14),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fechas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = _fechas[i];
                  final activo = d == _fecha;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () { _fecha = d; _cargarHoras(); },
                    child: Container(
                      width: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activo ? _azul : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: activo ? _azul : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dias[d.weekday - 1],
                              style: TextStyle(fontSize: 11, color: activo ? Colors.white : Colors.grey[600])),
                          Text('${d.day}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                  color: activo ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60, maxHeight: 220),
              child: FutureBuilder<List<String>>(
                future: _horas,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Text(snap.error.toString().replaceFirst('Exception: ', ''));
                  }
                  final horas = snap.data ?? [];
                  if (horas.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No hay horas libres este día.', style: TextStyle(color: Colors.grey[600])),
                    );
                  }
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: horas.map((h) => ChoiceChip(
                        label: Text(h),
                        selected: _hora == h,
                        onSelected: (_) => setState(() => _hora = h),
                      )).toList(),
                    ),
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _hora == null || _guardando ? null : _confirmar,
                child: Text(_guardando
                    ? 'Guardando…'
                    : _hora == null ? 'Elige una hora' : 'Cambiar a las $_hora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

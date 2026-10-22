/// lib/screens/agendar_screen.dart
///
/// "Agendar hora": A domicilio | Presencial | Telemedicina | Dermatología online.
/// Telemedicina: profesionales con horario de telemedicina (dermatología).
/// Dermatología online: sin hora — el paciente envía fotos, paga y un
/// dermatólogo le responde por correo (se abre la consulta online del centro).
/// 1. Centros que ofrecen esa modalidad.
/// 2. Dentro de cada centro, sus profesionales con su especialidad.
/// 3. "Agendar" abre la página de reservas del centro DENTRO de la app
///    (ReservaWebScreen, WebView en modo asistente), con el profesional ya
///    elegido y el RUT del paciente precargado (el propio o el de la persona
///    cuidada). Mismo flujo que la web: horas reales, dirección, pago con Flow.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/agenda_service.dart';
import '../widgets/etiqueta_especialidad.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'reserva_web_screen.dart';

const _azul = Color(0xFF1A3B8C);
const _verde = Color(0xFF0F766E);

class AgendarScreen extends StatefulWidget {
  final String modalidadInicial; // 'domicilio' | 'presencial' | 'telemedicina' | 'online'
  /// Cuidador agendando para la persona que cuida: se le recuerda usar
  /// el RUT de esa persona en la página de reservas.
  final String? paraNombre;
  final String? paraRut;
  const AgendarScreen({super.key, this.modalidadInicial = 'domicilio', this.paraNombre, this.paraRut});

  @override
  State<AgendarScreen> createState() => _AgendarScreenState();
}

class _AgendarScreenState extends State<AgendarScreen> {
  late String _modalidad;
  Future<List<CentroAgenda>>? _futureCentros;

  @override
  void initState() {
    super.initState();
    _modalidad = _modalidades.containsKey(widget.modalidadInicial) ? widget.modalidadInicial : 'domicilio';
    _iniciar();
  }

  /// Dirección del paciente para ordenar por cercanía (solo en la carpeta
  /// propia: de la persona cuidada no tenemos la dirección).
  String? _direccion;

  Future<void> _iniciar() async {
    if (widget.paraRut == null) {
      try {
        _direccion = (await AuthService.me()).direccion;
      } catch (_) {}
    }
    if (mounted) _cargar();
  }

  void _cargar() {
    setState(() {
      _futureCentros = AgendaService.centros(_modalidad, direccion: _direccion);
    });
  }

  void _cambiarModalidad(String m) {
    if (m == _modalidad) return;
    _modalidad = m;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(widget.paraNombre == null ? 'Agendar hora' : 'Agendar para ${widget.paraNombre}'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.6,
              children: _modalidades.entries.map((e) => _BotonModalidad(
                texto: e.value.$1,
                activo: _modalidad == e.key,
                onTap: () => _cambiarModalidad(e.key),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _modalidades[_modalidad]!.$2,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          if (widget.paraNombre != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Estás agendando para ${widget.paraNombre}: la reserva queda a su nombre.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<CentroAgenda>>(
              future: _futureCentros,
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
                          Text('${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                        ],
                      ),
                    ),
                  );
                }
                final centros = snapshot.data ?? [];
                if (centros.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Por ahora no hay ${_modalidades[_modalidad]!.$3} disponible.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if ((_direccion ?? '').isNotEmpty && _modalidad != 'online' && _modalidad != 'telemedicina')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('📍 Ordenado por cercanía a $_direccion',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    ...centros.map((c) => _TarjetaCentro(
                      centro: c, modalidad: _modalidad,
                      paraNombre: widget.paraNombre, paraRut: widget.paraRut,
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// modalidad → (botón, descripción, "no hay …")
const Map<String, (String, String, String)> _modalidades = {
  'domicilio': ('🏠 A domicilio', 'Un profesional te atiende en tu casa. El pago es en línea al reservar.',
      'atención a domicilio'),
  'presencial': ('🏥 Presencial', 'Reserva tu hora en uno de nuestros centros.', 'atención presencial'),
  'telemedicina': ('📱 Telemedicina', 'Consulta por videollamada a la hora que elijas.', 'telemedicina'),
  'online': ('💻 Derma online', 'Sin hora: envías tus fotos, pagas en línea y un dermatólogo te responde por correo.',
      'dermatología online'),
};

class _BotonModalidad extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  const _BotonModalidad({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFF0FDF9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? _verde : const Color(0xFFE2E8F0)),
        ),
        child: Text(texto,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: activo ? _verde : Colors.grey[700],
            )),
      ),
    );
  }
}

class _TarjetaCentro extends StatelessWidget {
  final CentroAgenda centro;
  final String modalidad;
  final String? paraNombre;
  final String? paraRut;
  const _TarjetaCentro({required this.centro, required this.modalidad, this.paraNombre, this.paraRut});

  /// Abre la reserva dentro de la app con el paciente precargado
  Future<void> _abrir(BuildContext context, Uri url) async {
    final rut = paraRut ?? await StorageService.obtenerRut();
    final nombre = paraRut != null ? (paraNombre ?? '') : (await StorageService.obtenerNombre() ?? '');
    if (!context.mounted) return;
    final resultado = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => ReservaWebScreen(
        url: url,
        titulo: centro.nombre,
        paciente: (rut ?? '').isEmpty ? null : {'rut': rut!, 'nombre': nombre},
      ),
    ));
    if (!context.mounted || resultado == null) return;
    final aviso = resultado == 'pago'
        ? 'Completa el pago: la hora queda apartada 30 minutos. También te llegó el link por correo.'
        : 'Hora reservada. Te llegará la confirmación por correo.';
    final mensajero = ScaffoldMessenger.maybeOf(context);
    // Volver a Agenda: ahí (y en Recordatorios) aparece la hora nueva
    Navigator.of(context).pop(resultado);
    mensajero?.showSnackBar(SnackBar(content: Text(aviso)));
  }

  Future<void> _agendar(BuildContext context, ProfesionalAgenda p) =>
      _abrir(context, centro.urlReservaDe(p, modalidad: modalidad));

  @override
  Widget build(BuildContext context) {
    final n = centro.profesionales.length;
    if (modalidad == 'online' && centro.urlOnline != null) {
      final precio = centro.precio ?? 0;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(centro.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(centro.profesionales.map((p) => p.nombre).join(', '),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              if (precio > 0)
                Text('Consulta online · \$${_miles(precio)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _verde)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _verde),
                  onPressed: () => _abrir(context, Uri.parse(centro.urlOnline!)),
                  child: const Text('Iniciar consulta online'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(centro.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$n ${n == 1 ? 'profesional' : 'profesionales'}${centro.soloDomicilio ? ' · Solo a domicilio' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: centro.profesionales.map((p) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      EtiquetaEspecialidad(especialidad: p.etiqueta),
                      if (modalidad == 'domicilio' && p.distanciaKm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('🏠 Sale a ${p.kmTexto} de tu domicilio',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ),
                      if (modalidad != 'domicilio' && p.lugar != null)
                        InkWell(
                          onTap: () => launchUrl(p.comoLlegar!, mode: LaunchMode.externalApplication),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '📍 ${[p.lugar!['nombre'], p.lugar!['direccion']].where((x) => (x ?? '').toString().isNotEmpty).join(' · ')}'
                              '${p.kmTexto.isNotEmpty ? ' · ${p.kmTexto}' : ''} · Cómo llegar',
                              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _verde),
                  onPressed: () => _agendar(context, p),
                  child: const Text('Agendar'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

String _miles(int n) {
  final t = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    if (i > 0 && (t.length - i) % 3 == 0) b.write('.');
    b.write(t[i]);
  }
  return b.toString();
}

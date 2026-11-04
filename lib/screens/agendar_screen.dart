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
import '../widgets/tarjetas.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'reserva_web_screen.dart';
import 'direccion_screen.dart';
import '../services/direccion_service.dart';

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
  bool _verTodos = false;   // presencial: también los centros a más de 50 km

  @override
  void initState() {
    super.initState();
    _modalidad = _modalidades.containsKey(widget.modalidadInicial) ? widget.modalidadInicial : 'domicilio';
    _iniciar();
  }

  /// Dirección del paciente para ordenar por cercanía (solo en la carpeta
  /// propia: de la persona cuidada no tenemos la dirección).
  String? _direccion;
  /// Domicilio (carpeta propia): SIEMPRE con la dirección registrada, nunca el
  /// GPS. Sin dirección o sin comuna se pide actualizarla antes de buscar.
  bool _dirConComuna = false;

  Future<void> _iniciar() async {
    if (widget.paraRut == null) {
      try {
        _direccion = (await AuthService.me()).direccion;
      } catch (_) {}
      try {
        _dirConComuna = DireccionService.tieneComuna(_direccion, await DireccionService.comunas());
      } catch (_) {
        // Sin lista de comunas (sin conexión): basta que tenga una comuna escrita
        _dirConComuna = (_direccion ?? '').contains(',');
      }
    }
    if (mounted) _cargar();
  }

  bool get _faltaDireccion => _modalidad == 'domicilio' && widget.paraRut == null && !_dirConComuna;

  void _cargar() {
    setState(() {
      _futureCentros = _faltaDireccion
          ? Future.value(const <CentroAgenda>[])
          : AgendaService.centros(_modalidad, direccion: _direccion, todos: _verTodos);
    });
  }

  Future<void> _editarDireccion() async {
    final nueva = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => DireccionScreen(actual: _direccion)));
    if (nueva == null || !mounted) return;
    _direccion = nueva;
    _dirConComuna = true;
    _cargar();
  }

  void _cambiarModalidad(String m) {
    if (m == _modalidad) return;
    _modalidad = m;
    _verTodos = false;
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
            // Mismo estilo que la Agenda (widgets/tarjetas.dart)
            child: GrillaOpciones(opciones: _modalidades.entries.map((e) => TarjetaOpcion(
              icono: e.value.$1.split(' ').first,
              titulo: e.value.$1.substring(e.value.$1.indexOf(' ') + 1),
              sub: _subtitulos[e.key],
              seleccionada: _modalidad == e.key,
              onTap: () => _cambiarModalidad(e.key),
            )).toList()),
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
          if (_faltaDireccion)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((_direccion ?? '').isEmpty ? '🏠 Agrega tu dirección' : '🏠 Actualiza tu dirección',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                  const SizedBox(height: 4),
                  Text(
                    (_direccion ?? '').isEmpty
                        ? 'Para ver quién puede atenderte en tu casa necesitamos tu dirección (calle, número y comuna).'
                        : 'A tu dirección registrada le falta la comuna. La necesitamos para saber quién puede ir a atenderte.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _verde),
                    onPressed: _editarDireccion,
                    child: Text((_direccion ?? '').isEmpty ? 'Agregar mi dirección' : 'Actualizar mi dirección'),
                  ),
                ],
              ),
            ),
          if (!_faltaDireccion && _modalidad == 'domicilio' && widget.paraRut == null && (_direccion ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('🏠 Visita en $_direccion',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[800])),
                  ),
                  TextButton(onPressed: _editarDireccion, child: const Text('Cambiar')),
                ],
              ),
            ),
          if (!_faltaDireccion)
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
                if (centros.isEmpty && _faltaDireccion) return const SizedBox.shrink();
                final hayMasLejos = _modalidad == 'presencial' && !_verTodos && AgendaService.ultimoMasLejos > 0;
                final botonMasLejos = OutlinedButton(
                  onPressed: () { _verTodos = true; _cargar(); },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _verde,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Ver centros más lejos (${AgendaService.ultimoMasLejos})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                );
                if (centros.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hayMasLejos
                                ? 'No hay centros a menos de 50 km de tu dirección.'
                                : 'Por ahora no hay ${_modalidades[_modalidad]!.$3} disponible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (hayMasLejos) ...[const SizedBox(height: 14), botonMasLejos],
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if ((_direccion ?? '').isNotEmpty && _modalidad == 'presencial')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('📍 Ordenado por cercanía a $_direccion',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ),
                    // Primero los centros (cerrados, el más cercano arriba); al
                    // tocar uno se ven sus profesionales. Con un solo centro, abierto.
                    ...centros.map((c) => _TarjetaCentro(
                      key: ValueKey('${_modalidad}_${c.id}'),
                      centro: c, modalidad: _modalidad, abierto: centros.length == 1,
                      paraNombre: widget.paraNombre, paraRut: widget.paraRut,
                      direccion: widget.paraRut == null ? _direccion : null,
                    )),
                    if (hayMasLejos) botonMasLejos,
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

const Map<String, String> _subtitulos = {
  'domicilio': 'Te atienden en casa',
  'presencial': 'En un centro',
  'telemedicina': 'Por videollamada',
  'online': 'Sin hora, con fotos',
};

/// modalidad → (botón, descripción, "no hay …")
const Map<String, (String, String, String)> _modalidades = {
  'domicilio': ('🏠 A domicilio', 'Un profesional te atiende en tu casa. El pago es en línea al reservar.',
      'atención a domicilio'),
  'presencial': ('🏥 Presencial', 'Reserva tu hora en uno de nuestros centros.', 'atención presencial'),
  'telemedicina': ('📱 Telemedicina', 'Consulta por videollamada a la hora que elijas.', 'telemedicina'),
  'online': ('💻 Derma online', 'Sin hora: envías tus fotos, pagas en línea y un dermatólogo te responde por correo.',
      'dermatología online'),
};

class _TarjetaCentro extends StatelessWidget {
  final CentroAgenda centro;
  final String modalidad;
  final String? paraNombre;
  final String? paraRut;
  final bool abierto;
  /// Dirección registrada del paciente (carpeta propia): domicilio se agenda ahí
  final String? direccion;
  const _TarjetaCentro({super.key, required this.centro, required this.modalidad, this.abierto = false,
      this.paraNombre, this.paraRut, this.direccion});

  /// Abre la reserva dentro de la app con el paciente precargado
  Future<void> _abrir(BuildContext context, Uri url) async {
    final rut = paraRut ?? await StorageService.obtenerRut();
    final nombre = paraRut != null ? (paraNombre ?? '') : (await StorageService.obtenerNombre() ?? '');
    if (!context.mounted) return;
    final resultado = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => ReservaWebScreen(
        url: url,
        titulo: centro.nombre,
        paciente: (rut ?? '').isEmpty ? null : {
          'rut': rut!, 'nombre': nombre,
          // La página de reservas usa esta dirección (no el GPS) para el domicilio
          if ((direccion ?? '').isNotEmpty) 'direccion': direccion!,
        },
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
    return _CentroDesplegable(
      centro: centro, modalidad: modalidad, abierto: abierto,
      onAgendar: (p) => _agendar(context, p),
    );
  }
}


/// v2: el centro con franja de color, iniciales y nombre destacado; cada
/// profesional en su propia tarjeta blanca (se distinguen de un vistazo).
class _CentroDesplegable extends StatefulWidget {
  final CentroAgenda centro;
  final String modalidad;
  final bool abierto;
  final void Function(ProfesionalAgenda) onAgendar;
  const _CentroDesplegable({required this.centro, required this.modalidad, required this.abierto,
      required this.onAgendar});

  @override
  State<_CentroDesplegable> createState() => _CentroDesplegableState();
}

class _CentroDesplegableState extends State<_CentroDesplegable> {
  late bool _abierto = widget.abierto;

  @override
  Widget build(BuildContext context) {
    final c = widget.centro;
    final n = c.profesionales.length;
    final subtitulo = [
      '$n ${n == 1 ? 'profesional' : 'profesionales'}',
      if (c.distanciaKm != null && widget.modalidad != 'online' && widget.modalidad != 'telemedicina')
        'a ${c.distanciaKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
    ].join(' · ');
    final especialidades = c.profesionales.map((p) => p.etiqueta).where((e) => e.isNotEmpty).toSet().toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_verde, Color(0xFF1B3B8C)]),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: Colors.white,
                    child: Text(iniciales(c.nombre),
                        style: const TextStyle(color: _verde, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nombre,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(subtitulo, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Icon(_abierto ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                ],
              ),
            ),
          ),
          if (!_abierto && especialidades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: especialidades.map((e) => EtiquetaEspecialidad(especialidad: e)).toList(),
              ),
            ),
          if (_abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
              child: Column(children: c.profesionales.map(_tarjetaProfesional).toList()),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaProfesional(ProfesionalAgenda p) {
    return TarjetaPersona(
      nombre: p.nombre,
      extra: [
        const SizedBox(height: 4),
        EtiquetaEspecialidad(especialidad: p.etiqueta),
        if (widget.modalidad == 'domicilio' && p.distanciaKm != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('🏠 Sale a ${p.kmTexto} de tu domicilio',
                style: const TextStyle(fontSize: 12, color: kTextoGris)),
          ),
        if (widget.modalidad != 'domicilio' && p.lugar != null)
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
      derecha: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _verde,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => widget.onAgendar(p),
        child: const Text('Agendar', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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

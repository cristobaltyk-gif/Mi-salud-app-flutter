/// lib/screens/cuidador_screen.dart
///
/// Pantalla de cuidadores con 2 sub-pestañas:
///   "Mis cuidadores" — el paciente invita (genera QR) y ve el estado de
///                       sus invitaciones (cuidador_router.py: /invitar,
///                       /mis-invitaciones, /invitar/{id} DELETE, /vinculo/{id} DELETE)
///   "A quién cuido"   — si esta cuenta también es cuidador de alguien más,
///                       puede escanear un QR y ver su lista (/escanear, /mis-cuidados)
///
/// Nota de diseño: en MiSalud, paciente y cuidador usan la MISMA cuenta —
/// no hay un rol separado. Por eso esta pantalla muestra ambos lados.
///
/// v1.1: cada tarjeta de "A quién cuido" ahora navega a FichaCuidadoScreen
/// al tocarla — antes no tenía ningún onTap, era el mismo gap que existía
/// en MisCuidados.jsx del lado web (ya corregido ahí).
///
/// v1.2: _EscanearQRScreen ahora acepta tanto un token crudo como una URL
/// completa (ej. "https://portal.hipokratia.health/cuidador/escanear/{token}").
/// El QR generado desde la web codifica la URL completa (para que también
/// funcione al escanearlo con la cámara nativa del teléfono, ej. cuando lo
/// usa un médico sin la app instalada), mientras que el QR generado desde
/// Flutter codifica solo el token crudo. Antes, si el QR venía de la web,
/// el scanner mandaba la URL completa tal cual como si fuera el token, lo
/// que nunca coincidía con el token_hash guardado en la base — causando
/// el error "Invitación no válida" (404) aunque la invitación fuera
/// perfectamente válida. Ahora se extrae el token del último segmento del
/// path si el valor leído es una URL.
///
/// v1.3 (mejora): _NuevaInvitacionSheetState ahora libera sus 4
/// TextEditingController en dispose() — antes no tenía ningún
/// dispose(), filtrando esos controllers cada vez que se cerraba la
/// hoja de "Invitar cuidador". También se agregan chequeos de
/// `mounted` antes de cada setState() posterior a un await en
/// _cargarNiveles() y _generar(), para no actualizar un widget ya
/// desmontado si el usuario cierra la hoja mientras la petición
/// sigue en curso.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/cuidador.dart';
import '../services/cuidador_service.dart';
import 'ficha_cuidado_screen.dart';

class CuidadorScreen extends StatefulWidget {
  const CuidadorScreen({super.key});

  @override
  State<CuidadorScreen> createState() => _CuidadorScreenState();
}

class _CuidadorScreenState extends State<CuidadorScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // v2: pantalla propia con barra de título (antes las pestañas quedaban
  // tapadas por la barra del teléfono) y dos botones grandes:
  // "Yo cuido" (primero) y "Me cuidan".
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuidadores'),
        backgroundColor: const Color(0xFF1B3B8C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Expanded(child: _BotonLado(
                  icono: '🤝', titulo: 'Yo cuido', sub: 'Personas que cuidas y tus invitaciones',
                  activo: _tabController.index == 0, onTap: () => _tabController.animateTo(0))),
                const SizedBox(width: 10),
                Expanded(child: _BotonLado(
                  icono: '🛡️', titulo: 'Me cuidan', sub: 'Quién puede ver tus recordatorios',
                  activo: _tabController.index == 1, onTap: () => _tabController.animateTo(1))),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AQuienCuidoTab(),
                _MisCuidadoresTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonLado extends StatelessWidget {
  final String icono, titulo, sub;
  final bool activo;
  final VoidCallback onTap;
  const _BotonLado({required this.icono, required this.titulo, required this.sub,
      required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF1B3B8C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activo ? azul : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activo ? azul : const Color(0xFFE2E8F0), width: 2),
          boxShadow: activo ? const [BoxShadow(color: Color(0x401B3B8C), blurRadius: 12, offset: Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icono, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: activo ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 11.5, height: 1.3,
                color: activo ? const Color(0xE6FFFFFF) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _MisCuidadoresTab extends StatefulWidget {
  const _MisCuidadoresTab();

  @override
  State<_MisCuidadoresTab> createState() => _MisCuidadoresTabState();
}

class _MisCuidadoresTabState extends State<_MisCuidadoresTab> {
  Future<List<InvitacionCuidador>>? _futureInvitaciones;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() { _futureInvitaciones = CuidadorService.misInvitaciones(); });
  }

  Future<void> _abrirNuevaInvitacion() async {
    final creada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NuevaInvitacionSheet(),
    );
    if (creada == true) _cargar();
  }

  Future<void> _revocar(InvitacionCuidador inv) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revocar acceso'),
        content: Text(
          inv.estado == 'pendiente'
              ? '¿Cancelar la invitación a ${inv.nombreCompleto}?'
              : '¿Quitarle acceso a ${inv.nombreCompleto}? Ya no podrá ver tus notificaciones.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revocar')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      if (inv.estado == 'pendiente') {
        await CuidadorService.revocarInvitacion(inv.id);
      } else {
        await CuidadorService.revocarVinculo(inv.id);
      }
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'vinculado': return Colors.green;
      case 'pendiente': return Colors.orange;
      case 'expirado': return Colors.grey;
      default: return Colors.red;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'vinculado': return 'Vinculado';
      case 'pendiente': return 'Esperando que acepte la invitación';
      case 'rechazado': return 'Rechazó la invitación';
      case 'expirado': return 'Expiró sin confirmar';
      default: return 'Revocado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevaInvitacion,
        icon: const Icon(Icons.qr_code),
        label: const Text('Agregar cuidador'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargar(),
        child: FutureBuilder<List<InvitacionCuidador>>(
          future: _futureInvitaciones,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final invitaciones = snapshot.data!;
            if (invitaciones.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(child: Column(children: [
                    Icon(Icons.people_outline, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('Aún no has invitado a ningún cuidador',
                        style: TextStyle(color: Colors.grey[600])),
                  ])),
                ),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: invitaciones.length,
              itemBuilder: (context, i) {
                final inv = invitaciones[i];
                final puedeRevocar = inv.estado == 'pendiente' || inv.estado == 'vinculado';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorEstado(inv.estado).withOpacity(0.15),
                      child: Icon(Icons.person_outline, color: _colorEstado(inv.estado)),
                    ),
                    title: Text(inv.nombreCompleto),
                    subtitle: Text(
                      '${_textoEstado(inv.estado)}'
                      '${inv.relacion != null && inv.relacion!.isNotEmpty ? ' · ${inv.relacion}' : ''}',
                      style: TextStyle(color: _colorEstado(inv.estado)),
                    ),
                    trailing: puedeRevocar
                        ? IconButton(icon: const Icon(Icons.close), onPressed: () => _revocar(inv))
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NuevaInvitacionSheet extends StatefulWidget {
  const _NuevaInvitacionSheet();
  @override
  State<_NuevaInvitacionSheet> createState() => _NuevaInvitacionSheetState();
}

class _NuevaInvitacionSheetState extends State<_NuevaInvitacionSheet> {
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _rutController = TextEditingController();
  final _relacionController = TextEditingController();
  List<NivelAcceso>? _niveles;
  String? _nivelSeleccionado;
  bool _cargandoNiveles = true;
  bool _enviando = false;
  String? _error;
  InvitacionGenerada? _invitacionCreada;

  @override
  void initState() {
    super.initState();
    _cargarNiveles();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _rutController.dispose();
    _relacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarNiveles() async {
    try {
      final niveles = await CuidadorService.nivelesAcceso();
      if (!mounted) return;
      setState(() {
        _niveles = niveles;
        _nivelSeleccionado = niveles.isNotEmpty ? niveles.first.valor : null;
        _cargandoNiveles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los niveles de acceso: $e';
        _cargandoNiveles = false;
      });
    }
  }

  Future<void> _generar() async {
    if (_nombreController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _rutController.text.trim().isEmpty ||
        _nivelSeleccionado == null) {
      setState(() => _error = 'Completa nombre, apellidos, RUT y nivel de acceso');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    try {
      final invitacion = await CuidadorService.invitar(
        cuidadorNombre: _nombreController.text.trim(),
        cuidadorApellidos: _apellidosController.text.trim(),
        cuidadorRut: _rutController.text.trim(),
        nivelAcceso: _nivelSeleccionado!,
        relacion: _relacionController.text.trim().isEmpty ? null : _relacionController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _invitacionCreada = invitacion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        if (_invitacionCreada != null) return _vistaQRGenerado(scrollController);
        return _vistaFormulario(scrollController);
      },
    );
  }

  Widget _vistaQRGenerado(ScrollController scrollController) {
    final inv = _invitacionCreada!;
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Código generado', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(data: inv.token, size: 220),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '✓ Invitación enviada. Tu cuidador debe aceptarla desde su cuenta, en '
            '"Cuidadores → Yo cuido". Si está contigo, también puede escanear este código. Vence el '
            '${inv.expiraInvitacion.day}/${inv.expiraInvitacion.month}/${inv.expiraInvitacion.year}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Text(inv.textoConsentimiento, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Listo')),
        ],
      ),
    );
  }

  Widget _vistaFormulario(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invitar a un cuidador', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _apellidosController,
              decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _rutController,
              decoration: const InputDecoration(labelText: 'RUT del cuidador',
                  hintText: '12345678-9', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _relacionController,
              decoration: const InputDecoration(labelText: 'Relación (opcional)',
                  hintText: 'Hijo, esposa, cuidador...', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          if (_cargandoNiveles)
            const Center(child: CircularProgressIndicator())
          else if (_niveles != null)
            ..._niveles!.map((nivel) => RadioListTile<String>(
                  value: nivel.valor,
                  groupValue: _nivelSeleccionado,
                  onChanged: (v) => setState(() => _nivelSeleccionado = v),
                  title: Text(nivel.valor[0].toUpperCase() + nivel.valor.substring(1)),
                  subtitle: Text(nivel.descripcion, style: const TextStyle(fontSize: 12)),
                )),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red[700])),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _enviando ? null : _generar,
            child: _enviando
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Generar código QR'),
          ),
        ],
      ),
    );
  }
}
class _AQuienCuidoTab extends StatefulWidget {
  const _AQuienCuidoTab();

  @override
  State<_AQuienCuidoTab> createState() => _AQuienCuidoTabState();
}

class _AQuienCuidoTabState extends State<_AQuienCuidoTab> {
  Future<List<PacienteCuidado>>? _futureCuidados;
  // v2: invitaciones que me hicieron (se aceptan o rechazan aquí)
  List<Map<String, dynamic>> _invitaciones = [];
  int? _ocupado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() { _futureCuidados = CuidadorService.misCuidados(); });
    CuidadorService.invitacionesRecibidas()
        .then((l) { if (mounted) setState(() => _invitaciones = l); })
        .catchError((_) {});
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _responder(Map<String, dynamic> inv, bool aceptar) async {
    setState(() => _ocupado = inv['id'] as int);
    try {
      await CuidadorService.responder(inv['id'] as int, aceptar: aceptar);
      _aviso(aceptar ? 'Ahora cuidas a ${inv['paciente']}' : 'Invitación rechazada');
      _cargar();
    } catch (e) {
      _aviso('$e');
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  /// QR en persona: muestra la invitación y se acepta o rechaza aquí mismo.
  Future<void> _escanear() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _EscanearQRScreen()),
    );
    if (token == null) return;
    try {
      final inv = await CuidadorService.verQR(token);
      if (!mounted) return;
      final aceptar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${inv['paciente']} te invita a ser su cuidador'),
          content: Text('Podrás recibir ${inv['que_podras_ver']}.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Rechazar', style: TextStyle(color: Colors.red))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aceptar')),
          ],
        ),
      );
      if (aceptar == null) return;
      await _responder(inv, aceptar);
    } catch (e) {
      _aviso('$e');
    }
  }

  Widget _tarjetaInvitacion(Map<String, dynamic> inv) {
    final relacion = (inv['relacion'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📩 ${inv['paciente']} te invita a ser su cuidador${relacion.isNotEmpty ? ' ($relacion)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Podrás recibir ${inv['que_podras_ver']}.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E))),
          const SizedBox(height: 10),
          Row(children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              onPressed: _ocupado == inv['id'] ? null : () => _responder(inv, true),
              child: const Text('✓ Aceptar'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _ocupado == inv['id'] ? null : () => _responder(inv, false),
              child: const Text('Rechazar'),
            ),
          ]),
        ],
      ),
    );
  }

  void _verFicha(String rutPaciente) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FichaCuidadoScreen(rutPaciente: rutPaciente)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _escanear,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear código'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargar(),
        child: FutureBuilder<List<PacienteCuidado>>(
          future: _futureCuidados,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final cuidados = snapshot.data!;
            if (cuidados.isEmpty) {
              return ListView(padding: const EdgeInsets.all(16), children: [
                ..._invitaciones.map(_tarjetaInvitacion),
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(child: Column(children: [
                    Icon(Icons.qr_code_scanner, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No cuidas a nadie todavía.\nCuando alguien te invite, la invitación aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ])),
                ),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _invitaciones.length + cuidados.length,
              itemBuilder: (context, i) {
                if (i < _invitaciones.length) return _tarjetaInvitacion(_invitaciones[i]);
                final c = cuidados[i - _invitaciones.length];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(c.nombreCompleto),
                    subtitle: Text(
                      'Acceso: ${c.nivelAcceso}'
                      '${c.relacion != null && c.relacion!.isNotEmpty ? ' · ${c.relacion}' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _verFicha(c.rutPaciente),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EscanearQRScreen extends StatefulWidget {
  const _EscanearQRScreen();

  @override
  State<_EscanearQRScreen> createState() => _EscanearQRScreenState();
}

class _EscanearQRScreenState extends State<_EscanearQRScreen> {
  bool _yaDetectado = false;

  /// Extrae el token de cuidador desde el valor crudo leído del QR.
  ///
  /// El QR puede venir en dos formatos válidos, según dónde se generó:
  ///   - Token crudo (generado desde Flutter): "AbCdEf123..."
  ///   - URL completa (generado desde la web, para que también funcione
  ///     al escanearlo con la cámara nativa del teléfono, ej. un médico
  ///     sin la app instalada): "https://portal.hipokratia.health/cuidador/escanear/AbCdEf123..."
  ///
  /// Si el valor parsea como una URI con esquema (http/https), se toma el
  /// último segmento del path como token. Si no, se asume que el valor ya
  /// es el token crudo y se usa tal cual.
  String _extraerToken(String valorCrudo) {
    final uri = Uri.tryParse(valorCrudo);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return valorCrudo;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaDetectado) return;
    final codigos = capture.barcodes;
    if (codigos.isEmpty) return;
    final valor = codigos.first.rawValue;
    if (valor == null || valor.isEmpty) return;
    _yaDetectado = true;
    Navigator.of(context).pop(_extraerToken(valor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          CustomPaint(
            painter: _QROverlayPainter(),
            child: const SizedBox.expand(),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código QR del paciente',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QROverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final obscuro = Paint()..color = Colors.black54;
    final borde = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final lado = size.width * 0.65;
    final izq = (size.width - lado) / 2;
    final arr = (size.height - lado) / 2;
    final rect = Rect.fromLTWH(izq, arr, lado, lado);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, obscuro);

    final esq = lado * 0.18;
    final esquinas = <List<double>>[
      [rect.left, rect.top, esq, 0, 0, esq],
      [rect.right, rect.top, -esq, 0, 0, esq],
      [rect.left, rect.bottom, esq, 0, 0, -esq],
      [rect.right, rect.bottom, -esq, 0, 0, -esq],
    ];
    for (final e in esquinas) {
      canvas.drawLine(Offset(e[0], e[1]), Offset(e[0] + e[2], e[1] + e[3]), borde);
      canvas.drawLine(Offset(e[0], e[1]), Offset(e[0] + e[4], e[1] + e[5]), borde);
    }
  }

  @override
  bool shouldRepaint(_QROverlayPainter old) => false;
}

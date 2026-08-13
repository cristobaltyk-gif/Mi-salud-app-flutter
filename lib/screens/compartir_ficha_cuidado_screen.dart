/// lib/screens/compartir_ficha_cuidado_screen.dart
///
/// Mismo flujo que la pantalla de "Autorizar acceso a médico" del propio
/// paciente, pero generando el acceso EN NOMBRE del paciente cuidado
/// (rutPaciente llega como argumento). El backend valida el vínculo
/// confirmado con nivel_acceso="completo" antes de aceptar cualquier
/// operación — esta pantalla nunca asume el permiso, solo lo solicita.
///
/// v1.1: agrega obtenerPerfilMedico() por cada link con medico_rut
/// (en_uso o historial), para mostrar nombre/título/especialidad del
/// médico — antes solo se veía el RUT crudo en el Chip. Dato público
/// RNPI, no bloqueante si falla (se muestra el RUT como respaldo).
///
/// v1.2 — FIX pantalla en blanco al escanear el QR: linkUrl se armaba
/// con AppConfig.backendBaseUrl (el dominio de la API, que solo sirve
/// JSON — no hay ninguna página ahí que renderizar). Ahora usa
/// AppConfig.misaludWebUrl, el dominio del frontend web donde vive
/// MedicoAcceso.jsx, la misma URL que ya usa correctamente el link
/// enviado por Email (armado del lado del backend en email_service.py).
///
/// v1.3 — FIX header "Modo cuidador" mostrándose siempre, incluso al
/// compartir tu propia ficha (esta pantalla se usa para ambos casos).
/// Para no requerir cambios en los widgets que navegan hasta acá, la
/// propia pantalla detecta si widget.rutPaciente coincide con el RUT
/// del usuario logueado (StorageService.obtenerRut()) y con eso decide
/// si mostrar el header morado y la mención al nombre del paciente
/// cuidado, o quedar neutra.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_config.dart';
import '../models/acceso_medico.dart';
import '../services/acceso_medico_service.dart';
import '../services/ficha_service.dart';
import '../services/storage_service.dart';

class CompartirFichaCuidadoScreen extends StatefulWidget {
  final String rutPaciente;

  const CompartirFichaCuidadoScreen({super.key, required this.rutPaciente});

  @override
  State<CompartirFichaCuidadoScreen> createState() => _CompartirFichaCuidadoScreenState();
}

class _CompartirFichaCuidadoScreenState extends State<CompartirFichaCuidadoScreen> {
  bool _esPropia = false;
  String? _nombrePaciente;
  List<AccesoMedico> _links = [];
  final Map<String, Map<String, dynamic>?> _perfiles = {};
  bool _loading = true;
  bool _generando = false;
  bool _enviando = false;
  String? _error;
  String? _exito;
  String _modo = 'qr'; // 'qr' | 'email'
  LinkGenerado? _linkActivo;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resolverSiEsPropia();
    _cargarLinks();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resolverSiEsPropia() async {
    final rutPropio = await StorageService.obtenerRut();
    final esPropia = rutPropio != null && rutPropio == widget.rutPaciente;
    if (!mounted) return;
    setState(() => _esPropia = esPropia);
    // Solo se consulta el nombre vía endpoint de cuidado cuando de verdad
    // es una persona cuidada — para el propio RUT ese endpoint no aplica
    // (no existe vínculo de cuidador contigo mismo) y daría 403.
    if (!esPropia) {
      _cargarNombrePaciente();
    }
  }

  Future<void> _cargarNombrePaciente() async {
    try {
      final ficha = await FichaService.obtenerFichaCuidado(widget.rutPaciente);
      if (!mounted) return;
      setState(() => _nombrePaciente = ficha.paciente.nombreCompleto);
    } catch (_) {
      // no bloqueante — si falla, simplemente no mostramos el nombre
    }
  }

  Future<void> _cargarLinks() async {
    setState(() => _loading = true);
    try {
      final links = await AccesoMedicoService.misLinks(rutPaciente: widget.rutPaciente);
      setState(() => _links = links);
      await _cargarPerfilesFaltantes(links);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarPerfilesFaltantes(List<AccesoMedico> links) async {
    final ruts = links
        .where((l) =>
            l.medicoRut != null &&
            l.medicoRut!.isNotEmpty &&
            (l.estado == EstadoAccesoMedico.enUso ||
                l.estado == EstadoAccesoMedico.cerrado ||
                l.estado == EstadoAccesoMedico.expirado))
        .map((l) => l.medicoRut!)
        .toSet();

    for (final rut in ruts) {
      if (_perfiles.containsKey(rut)) continue;
      final perfil = await AccesoMedicoService.obtenerPerfilMedico(rut);
      if (!mounted) return;
      setState(() => _perfiles[rut] = perfil);
    }
  }

  Future<void> _generarQR() async {
    setState(() {
      _generando = true;
      _error = null;
      _exito = null;
    });
    try {
      final link = await AccesoMedicoService.generarLink(rutPaciente: widget.rutPaciente);
      setState(() => _linkActivo = link);
      await _cargarLinks();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _generando = false);
    }
  }

  Future<void> _enviarEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Ingresa el email del médico');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
      _exito = null;
    });
    try {
      await AccesoMedicoService.enviarPorEmail(email, rutPaciente: widget.rutPaciente);
      setState(() {
        _exito = 'Acceso enviado a $email';
        _emailController.clear();
      });
      await _cargarLinks();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _enviando = false);
    }
  }

  Future<void> _revocar(int id) async {
    try {
      await AccesoMedicoService.revocarLink(id, rutPaciente: widget.rutPaciente);
      if (_linkActivo != null) setState(() => _linkActivo = null);
      setState(() {
        _links = _links
            .map((l) => l.id == id
                ? AccesoMedico(
                    id: l.id, medicoRut: l.medicoRut, token: l.token,
                    estado: EstadoAccesoMedico.revocado, creadoAt: l.creadoAt,
                    expiraInvitacion: l.expiraInvitacion, usadoAt: l.usadoAt,
                    expiraSesion: l.expiraSesion,
                  )
                : l)
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _links.where((l) => l.estaActivo).toList();
    final historial = _links.where((l) => !l.estaActivo).toList();
    final linkUrl = _linkActivo != null
        ? '${AppConfig.misaludWebUrl}/medico/acceso/${_linkActivo!.token}'
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!_esPropia)
              Container(
                width: double.infinity,
                color: const Color(0xFF4C1D95),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Modo cuidador', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          if (_nombrePaciente != null)
                            TextSpan(text: ' · Autorizando en nombre de $_nombrePaciente', style: const TextStyle(color: Colors.white)),
                        ]),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            AppBar(
              title: const Text('Autorizar acceso a médico'),
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: const Color(0xFFF5F3FF),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔐 ¿Cómo funciona?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C1D95))),
                          const SizedBox(height: 6),
                          Text(
                            _esPropia
                                ? 'Genera un acceso temporal para que un médico revise tu ficha. '
                                  'Podrá revisarla por 3 horas. Al cerrar sesión el acceso expira.'
                                : 'Genera un acceso temporal para que un médico revise la ficha'
                                  '${_nombrePaciente != null ? ' de $_nombrePaciente' : ' del paciente'}. '
                                  'Podrá revisarla por 3 horas. Al cerrar sesión el acceso expira.',
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _BotonModo(
                          texto: '📱 Código QR',
                          activo: _modo == 'qr',
                          onTap: () => setState(() => _modo = 'qr'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BotonModo(
                          texto: '📧 Email',
                          activo: _modo == 'email',
                          onTap: () => setState(() => _modo = 'email'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_modo == 'qr') ...[
                    if (_linkActivo == null)
                      FilledButton(
                        onPressed: _generando ? null : _generarQR,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_generando ? 'Generando...' : '+ Generar código QR'),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('Muestra este QR al médico', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              QrImageView(data: linkUrl!, size: 200),
                              const SizedBox(height: 16),
                              Text('El médico escanea con la cámara de su teléfono',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _generarQR,
                                      child: const Text('🔄 Nuevo QR'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      final link = _links.firstWhere(
                                        (l) => l.token == _linkActivo!.token,
                                        orElse: () => _links.first,
                                      );
                                      _revocar(link.id);
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Revocar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],

                  if (_modo == 'email')
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email del médico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'medico@ejemplo.cl',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _enviarEmail(),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _enviando ? null : _enviarEmail,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(_enviando ? 'Enviando...' : 'Enviar acceso por email'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                    ),
                  ],
                  if (_exito != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                      child: Text('✅ $_exito', style: TextStyle(color: Colors.green[800])),
                    ),
                  ],

                  if (_loading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  if (!_loading && pendientes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Accesos activos', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...pendientes.map((l) => _TarjetaAcceso(
                          link: l,
                          perfil: l.medicoRut != null ? _perfiles[l.medicoRut!] : null,
                          onRevocar: () => _revocar(l.id),
                        )),
                  ],

                  if (!_loading && historial.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Historial', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...historial.map((l) => _TarjetaHistorial(
                          link: l,
                          perfil: l.medicoRut != null ? _perfiles[l.medicoRut!] : null,
                        )),
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

class _BotonModo extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  const _BotonModo({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: activo ? const Color(0xFF0F766E) : Colors.white,
        foregroundColor: activo ? Colors.white : const Color(0xFF134E4A),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(texto),
    );
  }
}

/// Arma el bloque de identidad del médico (nombre, título, especialidad,
/// universidad, RUT) a partir del perfil público RNPI. Si no hay perfil
/// (médico ICA normal, no RNPI, o falló la consulta), muestra solo el RUT.
class _IdentidadMedico extends StatelessWidget {
  final String? rut;
  final Map<String, dynamic>? perfil;
  const _IdentidadMedico({required this.rut, required this.perfil});

  @override
  Widget build(BuildContext context) {
    if (rut == null) return const SizedBox.shrink();

    if (perfil == null) {
      return Text('👤 RUT $rut', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
    }

    final especialidadesRaw = perfil!['especialidades'] as List<dynamic>? ?? [];
    final especialidades = especialidadesRaw
        .map((e) => e is Map ? (e['nombre'] as String? ?? '') : e.toString())
        .where((s) => s.isNotEmpty)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('👤 ${perfil!['nombre'] ?? rut}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (perfil!['titulo'] != null)
          Text(perfil!['titulo'], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        if (especialidades.isNotEmpty)
          Text(especialidades, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
        if (perfil!['universidad'] != null)
          Text(perfil!['universidad'], style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }
}

class _TarjetaAcceso extends StatelessWidget {
  final AccesoMedico link;
  final Map<String, dynamic>? perfil;
  final VoidCallback onRevocar;
  const _TarjetaAcceso({required this.link, required this.perfil, required this.onRevocar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text(link.etiqueta, style: const TextStyle(fontSize: 11))),
              Text(
                '${link.creadoAt.day}/${link.creadoAt.month}/${link.creadoAt.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          if (link.medicoRut != null) ...[
            const SizedBox(height: 6),
            _IdentidadMedico(rut: link.medicoRut, perfil: perfil),
          ],
        ],
      ),
    );
  }
}

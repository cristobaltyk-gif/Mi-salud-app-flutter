/// lib/screens/lector_screen.dart — v1.2
///
/// v1.2: es la pantalla de "Autorizar" SIEMPRE (con o sin internet). El
/// paciente solo acepta y pone la huella; después la app decide sola:
///   1. Busca el Lector HypokratIA (15 s): "Acerque su teléfono al lector".
///   2. Si no aparece y hay internet → muestra el QR solo (enlace de un uso,
///      3 h) y SIGUE buscando: si el lector aparece, pasa a él y anula el QR.
///      Abajo, último recurso: "¿El médico no puede escanear? Enviar por email".
///   3. Sin lector ni internet → explica que con el Lector se puede, y sigue
///      buscando.
///   Si el teléfono no tiene la ficha guardada y hay internet, va directo al QR.
///
/// v1.1: el teléfono se anuncia y el PC del médico lo encuentra solo; ya no
/// hay lista para elegir.
///
/// "Autorizar médico" SIN INTERNET con el Lector HypokratIA (programa en el
/// PC del médico; después, la cajita). Pasos para la persona:
///   1. Acepta el mensaje de responsabilidad y confirma con huella.
///   2. La app busca el lector cerca (Bluetooth y red local a la vez).
///   3. Teléfono y PC muestran el mismo código de 4 números; el médico toca
///      ACEPTAR en su PC.
///   4. El médico ve la ficha y escribe en su PC; las notas y los accesos
///      quedan sellados en el teléfono y se envían solos al volver la red.
library;

import 'dart:async';
import '../i18n/idioma.dart';
import 'package:flutter/material.dart';
import '../services/biometria_service.dart';
import '../services/copia_cifrada_service.dart';
import '../services/lector_service.dart';
import '../services/http_sesion.dart' as http;
import '../services/acceso_medico_service.dart';
import '../models/acceso_medico.dart';
import '../config/app_config.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'compartir_ficha_cuidado_screen.dart';
import 'consulta_sin_conexion_screen.dart';

class LectorScreen extends StatefulWidget {
  final String rutPaciente;
  final bool esPropia;
  const LectorScreen({super.key, required this.rutPaciente, required this.esPropia});

  @override
  State<LectorScreen> createState() => _LectorScreenState();
}

class _LectorScreenState extends State<LectorScreen> {
  static const _morado = Color(0xFF4C1D95);
  bool _acepta = false;
  String _paso = 'aceptar'; // aceptar | buscando | nadie | sesion
  String? _error;
  Map<String, dynamic>? _ficha;
  DateTime? _aceptadaAt;
  SesionLector? _sesion;
  StreamSubscription<void>? _sub;

  // Paso 2 y 3 (sin lector a los 15 s)
  static const _esperaLector = Duration(seconds: 15);
  Timer? _reloj;
  bool _sinLector = false;      // pasaron los 15 s sin lector
  bool? _conInternet;           // null: revisando
  LinkGenerado? _link;
  String? _errorQr;

  @override
  void dispose() {
    _reloj?.cancel();
    _sub?.cancel();
    _sesion?.terminar();
    super.dispose();
  }

  // A los 15 s sin lector: QR si hay internet; si no, el aviso
  Future<void> _sinLectorTodavia() async {
    if (!mounted || _paso != 'buscando') return;
    setState(() => _sinLector = true);
    final red = await http.hayInternet();
    if (!mounted || _paso != 'buscando') return;
    setState(() => _conInternet = red);
    if (red) await _generarQr();
  }

  Future<void> _generarQr() async {
    try {
      final link = await AccesoMedicoService.generarLink(rutPaciente: widget.rutPaciente);
      if (!mounted) return;
      setState(() { _link = link; _errorQr = null; });
    } catch (e) {
      if (mounted) setState(() => _errorQr = e.toString());
    }
  }

  // Llegó el lector con un QR ya generado: se anula ese QR (no queda abierto)
  Future<void> _anularQr() async {
    final link = _link;
    if (link == null) return;
    _link = null;
    try {
      final links = await AccesoMedicoService.misLinks(rutPaciente: widget.rutPaciente);
      for (final l in links) {
        if (l.estado == EstadoAccesoMedico.pendiente) {
          await AccesoMedicoService.revocarLink(l.id, rutPaciente: widget.rutPaciente);
          break;   // el recién creado es el primero (más nuevo)
        }
      }
    } catch (_) {
      // Sin red o ya usado: el enlace vence solo
    }
  }

  void _irAlQr({String modo = 'qr'}) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: widget.rutPaciente, modoInicial: modo),
    ));
  }

  Future<void> _comenzar() async {
    setState(() => _error = null);
    final ok = await BiometriaService.autenticar(motivo: tr('Confirma que compartes la ficha bajo tu responsabilidad'));
    if (!ok) {
      setState(() => _error = BiometriaService.ultimoError ?? tr('No se confirmó tu identidad.'));
      return;
    }
    try {
      _ficha = await CopiaCifradaService.leerJson(
        rutCuidado: widget.esPropia ? null : widget.rutPaciente,
        pedirHuella: false,
      );
    } on CopiaException catch (e) {
      // Sin ficha guardada en el teléfono no hay lector; con internet, el QR
      if (await http.hayInternet()) {
        if (mounted) _irAlQr();
        return;
      }
      setState(() => _error = trp('{0} Abre la ficha una vez con internet para guardarla en el teléfono.', [e.mensaje]));
      return;
    }
    _aceptadaAt = DateTime.now();
    await _buscar();
  }

  Future<void> _buscar() async {
    final s = SesionLector(rutPaciente: widget.rutPaciente, ficha: _ficha!, aceptadaAt: _aceptadaAt!);
    _sub?.cancel();
    _sub = s.cambios.listen((_) {
      if (mounted && s.estado != 'conectando') {
        _reloj?.cancel();
        _anularQr();
        setState(() => _paso = 'sesion');
      }
    });
    setState(() {
      _sesion = s; _paso = 'buscando'; _error = null;
      _sinLector = false; _conInternet = null; _errorQr = null;
    });
    _reloj?.cancel();
    _reloj = Timer(_esperaLector, _sinLectorTodavia);
    try {
      // Sigue buscando el lector mientras se muestra el QR o el aviso
      final llego = await s.conectar(limite: const Duration(minutes: 10));
      if (!mounted) return;
      if (!llego) {
        _reloj?.cancel();
        // Con el QR a la vista no se interrumpe: el médico puede estar usándolo
        if (_link == null) setState(() => _paso = 'nadie');
      }
    } catch (e) {
      await s.terminar(avisar: false);
      if (mounted) setState(() { _paso = 'nadie'; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Autorizar médico')), backgroundColor: _morado, foregroundColor: Colors.white),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            switch (_paso) {
              'aceptar' => _vistaAceptar(),
              'buscando' => _vistaBuscando(),
              'nadie' => _vistaNadie(),
              _ => _vistaSesion(),
            },
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t, [IconData i = Icons.bluetooth_searching]) => Column(children: [
        Icon(i, color: _morado, size: 48),
        const SizedBox(height: 10),
        Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
      ]);

  Widget _vistaAceptar() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _titulo(tr('Compartir tu ficha con el médico'), Icons.medical_information),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _morado.withOpacity(0.3)),
          ),
          child: Text(
            widget.esPropia
                ? tr('Voy a mostrar mi ficha clínica a un profesional de la salud. Lo hago por mi propia decisión y '
                    'bajo mi responsabilidad. Sé que su identidad se verificará en el RNPI y que su nota no entrará '
                    'a mi ficha hasta esa verificación.')
                : tr('Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud, bajo mi '
                    'responsabilidad como su cuidador. Sé que su identidad se verificará en el RNPI y que su nota '
                    'no entrará a la ficha hasta esa verificación.'),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        CheckboxListTile(
          value: _acepta,
          onChanged: (v) => setState(() => _acepta = v ?? false),
          activeColor: _morado,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(tr('Acepto')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _morado),
          onPressed: _acepta ? _comenzar : null,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(tr('Confirmar con huella'))),
        ),
      ]);

  Widget _vistaBuscando() {
    // 1. Buscando el lector (primeros 15 s)
    if (!_sinLector || _conInternet == null) {
      return Column(children: [
        _titulo(tr('Acerque su teléfono al lector del médico')),
        const CircularProgressIndicator(),
        const SizedBox(height: 14),
        Text(tr('Mantén el teléfono cerca, con el Bluetooth encendido.'), textAlign: TextAlign.center),
      ]);
    }
    // 2. Sin lector, con internet: el QR solo
    if (_conInternet == true) {
      final url = _link == null ? null : '${AppConfig.misaludWebUrl}/medico/acceso/${_link!.token}';
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _titulo(tr('Muestre este código al médico'), Icons.qr_code_2),
        if (url != null)
          Center(child: QrImageView(data: url, size: 220))
        else if (_errorQr != null) ...[
          Text(_errorQr!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB91C1C))),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _generarQr, child: Text(tr('Intentar de nuevo'))),
        ] else
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Text(tr('El médico lo escanea con la cámara de su teléfono. Sirve una sola vez.'),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Flexible(child: Text(tr('Si el médico tiene el Lector HypokratIA, se conectará solo.'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        ]),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => _irAlQr(modo: 'email'),
          child: Text(tr('¿El médico no puede escanear? Enviar por email'), style: const TextStyle(fontSize: 13)),
        ),
      ]);
    }
    // 3. Sin lector ni internet
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _titulo(tr('No hay un lector cerca ni internet'), Icons.wifi_off),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
        child: Text(
          tr('Con el Lector HypokratIA el médico puede ver tu ficha aunque no haya internet. '
              'Pregúntale si tiene uno o acerca el teléfono a su lector.'),
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Flexible(child: Text(tr('Sigo buscando el lector…'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
      ]),
    ]);
  }

  Widget _vistaNadie() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _titulo(tr('No se encontró el lector del médico')),
        Text(
          tr('Verifica que el Lector HypokratIA esté enchufado al computador y que el Bluetooth del '
          'teléfono esté encendido.'),
          textAlign: TextAlign.center,
        ),
        if (LectorService.ultimoErrorBle != null) ...[
          const SizedBox(height: 8),
          Text(trp('Bluetooth: {0}', [LectorService.ultimoErrorBle]),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
        ],
        const SizedBox(height: 10),
        OutlinedButton(onPressed: _buscar, child: Text(tr('Intentar de nuevo'))),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ConsultaSinConexionScreen(rutPaciente: widget.rutPaciente, esPropia: widget.esPropia),
          )),
          child: Text(tr('Usar la red del teléfono (QR)')),
        ),
      ]);

  // Carnet del profesional (colores HypokratIA) con sello del RNPI
  Widget _profesional(ProfesionalLector p) {
    final d = p.rnpi ?? const {};
    final ok = p.estadoRnpi == 'ok';
    final nombre = (ok && d['nombre'] != null ? d['nombre'] : p.nombre).toString();
    final titulo = (d['titulo'] ?? '').toString();
    final especialidades = ((d['especialidades'] as List?) ?? const []).join(' · ');
    final universidad = (d['universidad'] ?? '').toString();
    const lila = Color(0xFFCECBF6);
    final aviso = switch (p.estadoRnpi) {
      'ok' => tr('Superintendencia de Salud · Registro Nacional de Prestadores'),
      'no' => tr('No aparece en el RNPI. Su nota quedará en revisión.'),
      'sin_red' => tr('Se verificará en el RNPI cuando vuelva internet.'),
      'error' => tr('El RNPI no respondió. Se verificará más tarde.'),
      _ => tr('Verificando en el RNPI…'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(color: _morado, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: _aro(170)),
        Positioned(right: -10, top: -10, child: _aro(110)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              const Text('HypokratIA',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const Spacer(),
              Text(tr('Profesional de la salud'), style: const TextStyle(color: lila, fontSize: 12, letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 60,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFEEEDFE), borderRadius: BorderRadius.circular(10)),
                child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(color: _morado, fontSize: 30, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 76),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nombre,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 2),
                    Text('RUT ${p.rut}', style: const TextStyle(color: lila, fontSize: 13)),
                    if (ok && (especialidades.isNotEmpty || titulo.isNotEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(especialidades.isNotEmpty ? especialidades : titulo,
                          style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.15)),
                      const SizedBox(height: 3),
                      Text(
                        [if (especialidades.isNotEmpty) titulo, universidad].where((x) => x.isNotEmpty).join(' · '),
                        style: const TextStyle(color: lila, fontSize: 13),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 86),
              child: Text(aviso, style: const TextStyle(color: lila, fontSize: 11.5)),
            ),
          ]),
        ),
        Positioned(right: 14, bottom: 12, child: _sello(p.estadoRnpi)),
      ]),
    );
  }

  Widget _aro(double t) => Container(
        width: t,
        height: t,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))),
      );

  // Sello oficial: blanco con morado (verificado), ámbar (no registrado), gris (pendiente)
  Widget _sello(String estado) {
    final (Color c, IconData icono, String linea1) = switch (estado) {
      'ok' => (_morado, Icons.verified, tr('Verificado')),
      'no' => (const Color(0xFFB45309), Icons.warning_amber_rounded, tr('No registrado')),
      _ => (const Color(0xFF6B7280), Icons.hourglass_top, tr('Pendiente')),
    };
    return Transform.rotate(
      angle: -0.21,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2)),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withOpacity(0.5), width: 1)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icono, color: c, size: 20),
              Text(linea1,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c, fontSize: 9.5, fontWeight: FontWeight.w800, height: 1.1)),
              Text('RNPI', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _vistaSesion() {
    final s = _sesion!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (s.estado == 'conectando') ...[
        _titulo(tr('Conectando…')),
        const Center(child: CircularProgressIndicator()),
      ] else if (s.estado == 'codigo') ...[
        _titulo(tr('Verifica el código'), Icons.verified_user),
        Text(tr('El computador del médico debe mostrar este mismo código:'), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(s.codigo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: 10, color: _morado)),
        const SizedBox(height: 8),
        Text(tr('Esperando que el médico toque ACEPTAR…'), textAlign: TextAlign.center),
      ] else if (s.estado == 'activa') ...[
        _titulo(tr('Consulta en curso'), Icons.medical_services),
        Text(trp('Computador: {0}', [s.equipo]), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (s.profesionales.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.hourglass_top, color: _morado),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('El médico aún no se identifica.'), style: const TextStyle(fontSize: 15))),
            ]),
          ),
        for (final p in s.profesionales) _profesional(p),
        Row(children: [
          const Icon(Icons.description_outlined, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(trp('Notas guardadas: {0} — se enviarán solas cuando vuelva internet.', [s.notas]),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
        ]),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
          onPressed: () => s.terminar(),
          child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(tr('Terminar'))),
        ),
      ] else ...[
        _titulo(s.estado == 'rechazada' ? tr('El médico no aceptó') : tr('Consulta terminada'), Icons.check_circle),
        Text(
          s.notas > 0
              ? trp('Se guardaron {0} nota(s). Se enviarán solas cuando vuelva internet.', [s.notas])
              : tr('El computador ya no tiene acceso a la ficha.'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _morado),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Listo')),
        ),
      ],
    ]);
  }
}

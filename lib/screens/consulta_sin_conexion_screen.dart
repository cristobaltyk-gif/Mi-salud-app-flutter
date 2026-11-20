/// lib/screens/consulta_sin_conexion_screen.dart — v1.1
///
/// v1.1: los dos QR van uno después del otro (paso 1: red; "Conectado ·
/// Siguiente"; paso 2: ficha), nunca los dos juntos.
///
/// Consulta SIN CONEXIÓN (Android): el paciente (o su cuidador con acceso
/// completo) acepta compartir la ficha bajo su responsabilidad, confirma con
/// huella y el teléfono abre una red local con dos QR:
///   1. Conectarse a la red del teléfono (se conecta solo al escanearlo).
///   2. Abrir la ficha en el navegador del profesional.
/// El profesional escribe su nota ahí; queda sellada y pendiente en el
/// teléfono y se envía sola cuando vuelva internet. Al salir de esta
/// pantalla, al tocar "Terminar" o al pasar 30 minutos, todo se apaga.
library;

import 'dart:async';
import '../i18n/idioma.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/biometria_service.dart';
import '../services/consulta_sin_conexion_service.dart';
import '../services/copia_cifrada_service.dart';

class ConsultaSinConexionScreen extends StatefulWidget {
  final String rutPaciente;
  final bool esPropia;
  const ConsultaSinConexionScreen({super.key, required this.rutPaciente, required this.esPropia});

  @override
  State<ConsultaSinConexionScreen> createState() => _ConsultaSinConexionScreenState();
}

class _ConsultaSinConexionScreenState extends State<ConsultaSinConexionScreen> {
  static const _morado = Color(0xFF4C1D95);
  bool _acepta = false;
  bool _cargando = false;
  String? _error;
  SesionConsulta? _sesion;
  StreamSubscription<void>? _sub;
  Timer? _tic;
  int _paso = 1; // uno a la vez: primero la red, luego la ficha

  @override
  void initState() {
    super.initState();
    _sub = ConsultaSinConexionService.cambios.listen((_) {
      if (!mounted) return;
      if (!ConsultaSinConexionService.activa && _sesion != null) {
        setState(() => _sesion = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tic?.cancel();
    ConsultaSinConexionService.terminar();
    super.dispose();
  }

  Future<void> _comenzar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final ok = await BiometriaService.autenticar(
        motivo: 'Confirma que compartes la ficha bajo tu responsabilidad',
      );
      if (!ok) throw ConsultaException(BiometriaService.ultimoError ?? 'No se confirmó tu identidad.');

      final Map<String, dynamic> ficha;
      try {
        ficha = await CopiaCifradaService.leerJson(
          rutCuidado: widget.esPropia ? null : widget.rutPaciente,
          pedirHuella: false,
        );
      } on CopiaException catch (e) {
        throw ConsultaException('${e.mensaje} Abre la ficha una vez con internet para guardarla en el teléfono.');
      }

      final sesion = await ConsultaSinConexionService.iniciar(
        rutPaciente: widget.rutPaciente,
        ficha: ficha,
        aceptadaAt: DateTime.now(),
      );
      _tic?.cancel();
      _tic = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
      setState(() { _sesion = sesion; _paso = 1; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _terminar() async {
    _tic?.cancel();
    await ConsultaSinConexionService.terminar();
    if (mounted) setState(() => _sesion = null);
  }

  String _restante(DateTime vence) {
    final d = vence.difference(DateTime.now());
    if (d.isNegative) return '0:00';
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Consulta sin conexión')),
        backgroundColor: _morado,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _sesion == null ? _vistaAceptar() : _vistaActiva(_sesion!)),
    );
  }

  Widget _vistaAceptar() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.wifi_tethering, color: _morado, size: 48),
        const SizedBox(height: 12),
        Text(tr('Compartir la ficha sin internet'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _morado.withOpacity(0.3)),
          ),
          child: Text(
            widget.esPropia
                ? 'Voy a mostrar mi ficha clínica a un profesional de la salud sin conexión a internet. '
                    'Lo hago por mi propia decisión y bajo mi responsabilidad. Sé que la identidad del '
                    'profesional se verificará en el RNPI cuando vuelva la conexión, y que su nota no '
                    'entrará a mi ficha hasta esa verificación.'
                : 'Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud sin '
                    'conexión a internet. Lo hago bajo mi responsabilidad como su cuidador. Sé que la '
                    'identidad del profesional se verificará en el RNPI cuando vuelva la conexión, y que su '
                    'nota no entrará a la ficha hasta esa verificación.',
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
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _morado),
          onPressed: (!_acepta || _cargando) ? null : _comenzar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _cargando
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(tr('Confirmar con huella y comenzar')),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
        ],
        const SizedBox(height: 18),
        Text(
          tr('El teléfono crea una red Wi-Fi propia (no da internet). El profesional se conecta, abre la ficha '
          'en su navegador y escribe su nota. No se descarga ningún archivo a su equipo. '
          'Dura 30 minutos o hasta que toques "Terminar".'),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _vistaActiva(SesionConsulta s) {
    final accesos = ConsultaSinConexionService.accesos;
    final notas = ConsultaSinConexionService.notasRecibidas;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Text('Termina en ${_restante(s.vence)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _morado, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        if (s.qrWifi != null && _paso == 1) ...[
          Text(tr('Paso 1 de 2 · Conectar el computador a este teléfono'),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Center(child: QrImageView(data: s.qrWifi!, size: 220)),
          Center(
            child: SelectableText('Red: ${s.ssid}\nClave: ${s.clave ?? ''}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _morado),
            onPressed: () => setState(() => _paso = 2),
            child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(tr('Conectado · Siguiente'))),
          ),
        ] else ...[
          Text(s.qrWifi != null ? 'Paso 2 de 2 · Abrir la ficha' : 'Abrir la ficha',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (s.qrWifi == null)
            Text(tr('El computador debe estar en la misma red Wi-Fi que este teléfono.'),
                style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Center(child: QrImageView(data: s.url, size: 220)),
          Center(child: SelectableText(s.url, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          if (s.qrWifi != null)
            TextButton(onPressed: () => setState(() => _paso = 1), child: Text(tr('Volver al paso 1'))),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(accesos.isEmpty ? 'Ningún profesional ha entrado todavía.' : 'Profesionales que entraron:',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              for (final a in accesos) Text('• ${a.nombre} (${a.rut})'),
              const SizedBox(height: 6),
              Text('Notas guardadas: $notas — se enviarán solas cuando vuelva internet.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
          onPressed: _terminar,
          child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(tr('Terminar'))),
        ),
      ],
    );
  }
}

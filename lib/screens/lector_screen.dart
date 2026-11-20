/// lib/screens/lector_screen.dart — v1.1
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

  @override
  void dispose() {
    _sub?.cancel();
    _sesion?.terminar();
    super.dispose();
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
      if (mounted && s.estado != 'conectando') setState(() => _paso = 'sesion');
    });
    setState(() { _sesion = s; _paso = 'buscando'; _error = null; });
    try {
      final llego = await s.conectar();
      if (!mounted) return;
      if (!llego) setState(() => _paso = 'nadie');
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
        _titulo(tr('Sin internet: compartir con el computador del médico')),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _morado.withOpacity(0.3)),
          ),
          child: Text(
            widget.esPropia
                ? tr('Voy a mostrar mi ficha clínica a un profesional de la salud sin conexión a internet. Lo hago '
                    'por mi propia decisión y bajo mi responsabilidad. Sé que su identidad se verificará en el RNPI '
                    'cuando vuelva la conexión, y que su nota no entrará a mi ficha hasta esa verificación.')
                : tr('Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud sin conexión '
                    'a internet, bajo mi responsabilidad como su cuidador. Sé que su identidad se verificará en el '
                    'RNPI cuando vuelva la conexión, y que su nota no entrará a la ficha hasta esa verificación.'),
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
          child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(tr('Confirmar con huella y buscar'))),
        ),
      ]);

  Widget _vistaBuscando() => Column(children: [
        _titulo(tr('Esperando al computador del médico…')),
        const CircularProgressIndicator(),
        const SizedBox(height: 14),
        Text(tr('Mantén el teléfono cerca del computador, con el Bluetooth encendido.'),
            textAlign: TextAlign.center),
      ]);

  Widget _vistaNadie() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _titulo(tr('No se encontró el computador del médico')),
        Text(
          tr('Verifica que el programa Lector HypokratIA esté abierto en el computador y que el Bluetooth del '
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.profesionales.isEmpty ? tr('El médico aún no se identifica.') : tr('Profesionales:'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final p in s.profesionales) Text('• $p'),
            const SizedBox(height: 6),
            Text(trp('Notas guardadas: {0} — se enviarán solas cuando vuelva internet.', [s.notas])),
          ]),
        ),
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

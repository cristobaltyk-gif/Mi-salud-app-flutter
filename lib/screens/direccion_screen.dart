/// lib/screens/direccion_screen.dart
///
/// "Mi dirección": calle, número, depto/oficina y comuna (de la lista de las
/// 346 comunas; la región aparece sola). "Ver en el mapa" la ubica y muestra
/// el punto; "Sí, es aquí" la guarda en MiSalud. Se usa al agendar a
/// domicilio cuando no hay dirección registrada o le falta la comuna.
/// Devuelve (pop) la dirección guardada, o null si se canceló.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/direccion_service.dart';

const _verde = Color(0xFF0F766E);

class DireccionScreen extends StatefulWidget {
  final String? actual;
  const DireccionScreen({super.key, this.actual});

  @override
  State<DireccionScreen> createState() => _DireccionScreenState();
}

class _DireccionScreenState extends State<DireccionScreen> {
  final _calle = TextEditingController();
  final _numero = TextEditingController();
  final _depto = TextEditingController();
  String _comuna = '';
  String _region = '';
  List<Comuna> _comunas = [];
  bool _buscando = false;
  bool _guardando = false;
  String? _error;
  DireccionVerificada? _verif;
  WebViewController? _mapa;

  @override
  void initState() {
    super.initState();
    DireccionService.comunas().then((l) {
      if (!mounted) return;
      setState(() => _comunas = l);
      _precargar(widget.actual ?? '');
    }).catchError((_) {
      if (mounted) setState(() => _error = 'No se pudo cargar la lista de comunas. Revisa tu conexión.');
    });
  }

  /// "Av. España 998, Depto 2, Curicó" → campos (mejor esfuerzo)
  void _precargar(String texto) {
    final partes = texto.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return;
    if (partes.length > 1) {
      final n = DireccionService.normalizar(partes.last);
      final c = _comunas.where((c) => DireccionService.normalizar(c.nombre) == n);
      if (c.isNotEmpty) {
        _comuna = c.first.nombre;
        _region = c.first.region;
        partes.removeLast();
      }
    }
    final primera = partes.removeAt(0);
    final m = RegExp(r'^(.*?\D)\s+(\d+[A-Za-z]?(?:-\d+)?|S/N)$', caseSensitive: false).firstMatch(primera);
    _calle.text = m != null ? m.group(1)!.trim() : primera;
    _numero.text = m != null ? m.group(2)! : '';
    _depto.text = partes.join(', ');
    setState(() {});
  }

  void _cambio() {
    if (_verif != null || _error != null) setState(() { _verif = null; _error = null; });
  }

  Future<void> _verMapa() async {
    if (_calle.text.trim().isEmpty) { setState(() => _error = 'Escribe la calle.'); return; }
    if (_numero.text.trim().isEmpty) { setState(() => _error = 'Escribe el número (si no tiene, S/N).'); return; }
    if (_comuna.isEmpty) { setState(() => _error = 'Elige la comuna de la lista.'); return; }
    setState(() { _buscando = true; _error = null; _verif = null; });
    try {
      final v = await DireccionService.verificar(
          calle: _calle.text.trim(), numero: _numero.text.trim(), comuna: _comuna, depto: _depto.text.trim());
      if (!mounted) return;
      if (!v.ok || v.lat == null || v.lng == null) {
        setState(() => _error = v.mensaje.isNotEmpty ? v.mensaje : 'No encontramos esa dirección.');
      } else {
        const d = 0.004;
        final url = 'https://www.openstreetmap.org/export/embed.html?bbox='
            '${v.lng! - d},${v.lat! - d * 0.7},${v.lng! + d},${v.lat! + d * 0.7}'
            '&layer=mapnik&marker=${v.lat},${v.lng}';
        _mapa = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url));
        setState(() => _verif = v);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Sin conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _confirmar() async {
    final v = _verif;
    if (v == null) return;
    setState(() { _guardando = true; _error = null; });
    try {
      await DireccionService.guardar(v.direccion);
      if (mounted) Navigator.of(context).pop(v.direccion);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi dirección'),
        backgroundColor: const Color(0xFF1A3B8C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Donde te atienden a domicilio. Escribe calle, número y elige la comuna; '
              'después confírmala en el mapa.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(flex: 3, child: TextField(controller: _calle, decoration: _deco('Calle', hint: 'Av. España'),
                textCapitalization: TextCapitalization.words, onChanged: (_) => _cambio())),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: TextField(controller: _numero, decoration: _deco('Número', hint: '998'),
                onChanged: (_) => _cambio())),
          ]),
          const SizedBox(height: 10),
          Autocomplete<Comuna>(
            key: ValueKey('comuna-${_comunas.length}'),
            initialValue: TextEditingValue(text: _comuna),
            displayStringForOption: (c) => c.nombre,
            optionsBuilder: (t) {
              final q = DireccionService.normalizar(t.text);
              if (q.isEmpty) return const Iterable<Comuna>.empty();
              return _comunas.where((c) => DireccionService.normalizar(c.nombre).startsWith(q)).take(8);
            },
            onSelected: (c) => setState(() { _comuna = c.nombre; _region = c.region; _verif = null; _error = null; }),
            fieldViewBuilder: (ctx, ctrl, foco, alEnviar) => TextField(
              controller: ctrl,
              focusNode: foco,
              decoration: _deco('Comuna', hint: 'Escribe y elige de la lista'),
              onChanged: (t) {
                // Si lo escrito ya no es la comuna elegida, hay que volver a elegir
                if (DireccionService.normalizar(t) != DireccionService.normalizar(_comuna)) {
                  setState(() { _comuna = ''; _region = ''; _verif = null; });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_region.isNotEmpty ? 'Región: $_region' : 'Elige una comuna de la lista',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          const SizedBox(height: 10),
          TextField(controller: _depto, decoration: _deco('Depto / oficina (opcional)'), onChanged: (_) => _cambio()),
          const SizedBox(height: 14),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA))),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
            ),
          if (_verif == null)
            OutlinedButton.icon(
              onPressed: _buscando ? null : _verMapa,
              icon: const Icon(Icons.place_outlined),
              label: Text(_buscando ? 'Buscando…' : 'Ver en el mapa'),
            ),
          if (_verif != null && _mapa != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 200, child: WebViewWidget(controller: _mapa!)),
            ),
            const SizedBox(height: 8),
            Text('📍 ${_verif!.encontrada.isNotEmpty ? _verif!.encontrada : _verif!.direccion}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('¿El punto está en el lugar correcto?', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _verde),
                  onPressed: _guardando ? null : _confirmar,
                  child: Text(_guardando ? 'Guardando…' : '✓ Sí, es aquí'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _guardando ? null : () => setState(() => _verif = null),
                child: const Text('No, corregir'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

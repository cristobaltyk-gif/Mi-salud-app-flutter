/// lib/screens/reserva_web_screen.dart
///
/// Reserva dentro de la app (sin salir al navegador): la página de reservas
/// del centro se abre en un WebView en "modo asistente", con el paciente ya
/// identificado (el RUT llega precargado y la página busca su ficha sola).
///
/// Protocolo con la página (roles/BookingCerebro.jsx del frontend de ICA):
/// - La página envía por el canal JavaScript "HypokratiaApp":
///     listo      → la app le manda los datos del paciente
///     reservado  → hora tomada (presencial / telemedicina)
///     pagar      → domicilio: se abre el pago de Flow y se vuelve a Agenda
/// - La app responde con el evento "hipokratia-app"
///   (detail = { fuente: "ica-asistente", tipo: "paciente", datos }).
///
/// Seguridad: el WebView solo navega dentro de *.icarticular.cl y
/// *.hipokratia.health; cualquier otro enlace (Flow, etc.) se abre fuera
/// del WebView, en el navegador interno de la app.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _azul = Color(0xFF1A3B8C);

/// Resultado al cerrar: 'reservado' | 'pago' | null (volvió sin reservar)
class ReservaWebScreen extends StatefulWidget {
  final Uri url;
  final String titulo;
  /// Datos del paciente para precargar (rut obligatorio para precargar).
  final Map<String, String>? paciente;

  const ReservaWebScreen({super.key, required this.url, required this.titulo, this.paciente});

  @override
  State<ReservaWebScreen> createState() => _ReservaWebScreenState();
}

class _ReservaWebScreenState extends State<ReservaWebScreen> {
  late final WebViewController _web;
  int _progreso = 0;
  String? _error;

  static final _dominiosPropios = RegExp(r'(^|\.)(icarticular\.cl|hipokratia\.health)$');

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('HypokratiaApp', onMessageReceived: (m) => _alMensaje(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) { if (mounted) setState(() => _progreso = p); },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) {
            if (mounted) setState(() => _error = 'No se pudo cargar la página de reservas.');
          }
        },
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme == 'https' && _dominiosPropios.hasMatch(uri.host)) {
            return NavigationDecision.navigate;
          }
          // Pago u otro sitio: fuera del WebView
          _abrirFuera(uri, esPago: uri.host.endsWith('flow.cl'));
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(widget.url);
  }

  Future<void> _abrirFuera(Uri uri, {bool esPago = false}) async {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (esPago && mounted) Navigator.of(context).pop('pago');
  }

  void _alMensaje(String texto) {
    Map<String, dynamic> d;
    try {
      d = jsonDecode(texto) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (d['fuente'] != 'ica-reservas') return;
    switch (d['tipo']) {
      case 'listo':
        _enviarPaciente();
        break;
      case 'reservado':
        if (mounted) Navigator.of(context).pop('reservado');
        break;
      case 'pagar':
        final url = Uri.tryParse(d['url']?.toString() ?? '');
        if (url != null && url.scheme == 'https' && url.host.endsWith('flow.cl')) {
          _abrirFuera(url, esPago: true);
        }
        break;
    }
  }

  void _enviarPaciente() {
    final p = widget.paciente;
    if (p == null || (p['rut'] ?? '').isEmpty) return;
    final detalle = jsonEncode({'fuente': 'ica-asistente', 'tipo': 'paciente', 'datos': p});
    _web.runJavaScript(
        "window.dispatchEvent(new CustomEvent('hipokratia-app', {detail: $detalle}));");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        bottom: _progreso < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progreso / 100, minHeight: 3),
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () { setState(() => _error = null); _web.loadRequest(widget.url); },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _web),
    );
  }
}

/// lib/screens/activar_cuenta_screen.dart — v2.0
///
/// v2.0 (alineado con misalud-backend ya corregido — auditoría CRÍTICO-2):
/// antes pedía RUT + email + contraseña en un solo paso y llamaba a
/// POST /api/auth/activar, endpoint que ya no existe. Ahora solo pide
/// el RUT: si corresponde a una ficha registrada, el backend envía un
/// link de activación de un solo uso al correo asociado. El paciente
/// completa la activación (confirmar datos + crear clave) en ese link,
/// en el navegador del teléfono — la app no maneja el token del link
/// (deep linking evaluado a futuro, requiere signing de producción y
/// publicación en tiendas, que aún no existen). Después de activar en
/// el navegador, el paciente vuelve a la app y hace login normal.
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ActivarCuentaScreen extends StatefulWidget {
  final String? rutInicial;

  const ActivarCuentaScreen({super.key, this.rutInicial});

  @override
  State<ActivarCuentaScreen> createState() => _ActivarCuentaScreenState();
}

class _ActivarCuentaScreenState extends State<ActivarCuentaScreen> {
  late final TextEditingController _rutController;

  bool _cargando = false;
  bool _enviado = false;
  String? _error;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _rutController = TextEditingController(text: widget.rutInicial ?? '');
  }

  @override
  void dispose() {
    _rutController.dispose();
    super.dispose();
  }

  Future<void> _solicitarActivacion() async {
    final rut = _rutController.text.trim();

    if (rut.isEmpty) {
      setState(() => _error = 'Ingresa tu RUT');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final mensaje = await AuthService.buscarRut(rut);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _mensaje = mensaje;
      });
    } on AuthException catch (e) {
      setState(() => _error = e.mensaje);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar. Revisa tu conexión a internet.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activar mi cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_enviado) ...[
                Text(
                  'Si tu médico ya creó tu ficha en MiSalud, ingresa tu RUT '
                  'y te enviaremos un link de activación a tu correo registrado.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _rutController,
                  onSubmitted: (_) => _solicitarActivacion(),
                  decoration: const InputDecoration(
                    labelText: 'RUT',
                    hintText: '12345678-9',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _solicitarActivacion,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar link de activación'),
                ),
              ] else ...[
                Icon(Icons.mark_email_read_outlined, size: 56, color: Colors.teal[700]),
                const SizedBox(height: 16),
                Text(
                  _mensaje ?? 'Revisa tu correo para continuar.',
                  style: TextStyle(color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Abre el link desde tu teléfono para confirmar tus datos y crear '
                  'tu contraseña. Luego vuelve aquí e inicia sesión.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

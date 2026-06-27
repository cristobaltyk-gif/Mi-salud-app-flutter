/// lib/screens/activar_cuenta_screen.dart
///
/// Activación de cuenta para pacientes que ya existen en la base (su
/// médico los registró) pero nunca crearon una contraseña. Usa
/// POST /api/auth/activar, que valida que el email coincida con el
/// registrado antes de permitir crear la clave (auth_router.py).
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class ActivarCuentaScreen extends StatefulWidget {
  final String? rutInicial;

  const ActivarCuentaScreen({super.key, this.rutInicial});

  @override
  State<ActivarCuentaScreen> createState() => _ActivarCuentaScreenState();
}

class _ActivarCuentaScreenState extends State<ActivarCuentaScreen> {
  late final TextEditingController _rutController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _cargando = false;
  String? _error;
  bool _ocultarPassword = true;

  @override
  void initState() {
    super.initState();
    _rutController = TextEditingController(text: widget.rutInicial ?? '');
  }

  @override
  void dispose() {
    _rutController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    final rut = _rutController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmar = _confirmarPasswordController.text;

    if (rut.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (password != confirmar) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await AuthService.activarCuenta(
        rut: rut,
        email: email,
        nuevaPassword: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
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
              Text(
                'Tu médico ya creó tu ficha en MiSalud. Activa tu cuenta '
                'ingresando tu RUT, tu email registrado, y una contraseña nueva.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _rutController,
                decoration: const InputDecoration(
                  labelText: 'RUT',
                  hintText: '12345678-9',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email registrado',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText: 'Mínimo 8 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmarPasswordController,
                obscureText: _ocultarPassword,
                onSubmitted: (_) => _activar(),
                decoration: const InputDecoration(
                  labelText: 'Confirma tu contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
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
                onPressed: _cargando ? null : _activar,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Activar cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

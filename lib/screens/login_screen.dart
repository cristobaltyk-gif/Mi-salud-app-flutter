/// lib/screens/login_screen.dart
///
/// Pantalla de inicio de sesión. Diferencia los 3 casos de error reales
/// de POST /api/auth/login (auth_router.py v1.5):
///   404 → RUT no registrado
///   401 "Cuenta no activada" → redirige a activar cuenta
///   401 "Contraseña incorrecta" → mensaje de error normal
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'activar_cuenta_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  String? _error;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _rutController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _intentarLogin() async {
    final rut = _rutController.text.trim();
    final password = _passwordController.text;

    if (rut.isEmpty || password.isEmpty) {
      setState(() => _error = 'Ingresa tu RUT y tu contraseña');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await AuthService.login(rut, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      // Cuenta no activada: lo más útil es llevar directo a activar,
      // no solo mostrar el error y dejar al paciente sin saber qué hacer.
      if (e.statusCode == 401 && e.mensaje == 'Cuenta no activada') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivarCuentaScreen(rutInicial: rut),
          ),
        );
        return;
      }

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.health_and_safety_outlined, size: 72, color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                Text(
                  'MiSalud',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Instituto de Cirugía Articular',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _rutController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'RUT',
                    hintText: '12345678-9',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _intentarLogin(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
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
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _intentarLogin,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Ingresar'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _cargando
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivarCuentaScreen(),
                            ),
                          );
                        },
                  child: const Text('¿Primera vez? Activa tu cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// lib/screens/login_screen.dart
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'activar_cuenta_screen.dart';
import 'dashboard_screen.dart';

// --- Colores de marca HypokratIA ---
const Color kHypoBlue = Color(0xFF1A3B8C);
const Color kHypoBlueDark = Color(0xFF0F235A);
const Color kHypoTeal = Color(0xFF0F9B8E);
const Color kHypoTealDark = Color(0xFF0B2E45);

String _normalizarRut(String raw) {
  final limpio = raw.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.length < 2) return limpio;
  final cuerpo = limpio.substring(0, limpio.length - 1);
  final dv = limpio[limpio.length - 1];
  return '$cuerpo-$dv';
}

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

  void _onRutChanged(String value) {
    final normalizado = _normalizarRut(value);
    if (normalizado != value) {
      _rutController.value = _rutController.value.copyWith(
        text: normalizado,
        selection: TextSelection.collapsed(offset: normalizado.length),
      );
    }
  }

  Future<void> _intentarLogin() async {
    final rut = _rutController.text.trim();
    final password = _passwordController.text;
    if (rut.isEmpty || password.isEmpty) {
      setState(() => _error = 'Ingresa tu RUT y tu contraseña');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      await AuthService.login(rut, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 && e.mensaje == 'Cuenta no activada') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActivarCuentaScreen(rutInicial: rut)),
        );
        return;
      }
      setState(() => _error = e.mensaje);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kHypoBlue, kHypoTealDark, Color(0xFF071A26)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/hypokratia_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
                      children: [
                        TextSpan(text: 'Hypokrat', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'IA', style: TextStyle(color: kHypoTeal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Software Médico',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 40),
                  // Card de formulario
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ingresa a tu cuenta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kHypoBlueDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _rutController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onChanged: _onRutChanged,
                          decoration: InputDecoration(
                            labelText: 'RUT',
                            hintText: '12345678-9',
                            prefixIcon: const Icon(Icons.badge_outlined, color: kHypoTeal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kHypoTeal, width: 2),
                            ),
                            labelStyle: const TextStyle(color: kHypoTeal),
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
                            prefixIcon: const Icon(Icons.lock_outline, color: kHypoTeal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kHypoTeal, width: 2),
                            ),
                            labelStyle: const TextStyle(color: kHypoTeal),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                                color: kHypoTeal,
                              ),
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
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _intentarLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kHypoBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _cargando
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _cargando ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ActivarCuentaScreen()),
                      );
                    },
                    child: Text(
                      '¿Primera vez? Activa tu cuenta',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

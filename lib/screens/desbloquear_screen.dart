/// lib/screens/desbloquear_screen.dart — v1.0
///
/// Entrar con huella o rostro (o el PIN del teléfono):
///  - renovar:  la sesión venció → huella → sesión nueva sin contraseña
///              (POST /api/auth/renovar con la llave del teléfono) → inicio.
///  - bloqueo:  la app estuvo 5 minutos o más en segundo plano → huella →
///              vuelve a donde estaba (si además venció la sesión, la renueva).
/// "Usar mi contraseña" lleva al inicio de sesión de siempre.
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometria_service.dart';
import '../services/http_sesion.dart' show SesionVencida;
import '../services/storage_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class DesbloquearScreen extends StatefulWidget {
  /// true: vuelve a la pantalla anterior al desbloquear (bloqueo por inactividad)
  final bool bloqueo;
  const DesbloquearScreen({super.key, this.bloqueo = false});

  /// Hay una pantalla de desbloqueo abierta (para no apilar otra)
  static bool abierta = false;

  @override
  State<DesbloquearScreen> createState() => _DesbloquearScreenState();
}

class _DesbloquearScreenState extends State<DesbloquearScreen> {
  bool _ocupado = false;
  String? _error;
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    DesbloquearScreen.abierta = true;
    StorageService.obtenerNombre().then((n) {
      if (mounted) setState(() => _nombre = (n ?? '').split(' ').first);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquear());
  }

  @override
  void dispose() {
    DesbloquearScreen.abierta = false;
    super.dispose();
  }

  Future<void> _desbloquear() async {
    if (_ocupado) return;
    setState(() { _ocupado = true; _error = null; });
    try {
      final ok = await BiometriaService.autenticar();
      if (!ok) {
        setState(() => _error = 'No se pudo confirmar. Toca el botón para intentar de nuevo.');
        return;
      }
      final token = await StorageService.obtenerToken();
      if (SesionVencida.tokenVencido(token)) {
        await AuthService.renovar();
      }
      if (!mounted) return;
      if (widget.bloqueo && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (e.statusCode == 403) {
        _usarContrasena(aviso: 'Este teléfono ya no está vinculado. Ingresa con tu contraseña.');
        return;
      }
      setState(() => _error = e.mensaje);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _usarContrasena({String? aviso}) async {
    await StorageService.cerrarSesionVencida();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(aviso: aviso)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // no se puede saltar con el botón atrás
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3B8C), Color(0xFF123566), Color(0xFF0B2E45)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/images/hypokratia_icon.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _nombre.isNotEmpty ? 'Hola, $_nombre' : 'MiSalud',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bloqueo
                        ? 'Confirma que eres tú para seguir.'
                        : 'Entra con tu huella para ver tu ficha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _ocupado ? null : _desbloquear,
                      icon: _ocupado
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A3B8C)))
                          : const Icon(Icons.fingerprint, size: 28),
                      label: const Text('Entrar con huella', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A3B8C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _ocupado ? null : () => _usarContrasena(),
                    child: const Text('Usar mi contraseña', style: TextStyle(color: Colors.white, fontSize: 14)),
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

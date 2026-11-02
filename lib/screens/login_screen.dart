/// lib/screens/login_screen.dart — v1.2
///
/// v1.3: teléfono nuevo → código de 6 dígitos que llega al correo (fase
/// "código" en esta misma tarjeta). Al entrar, si el teléfono tiene huella
/// y aún no se le preguntó, ofrece "Entrar con huella" (DesbloquearScreen).
/// v1.2: aviso opcional arriba del formulario (p. ej. "Tu sesión expiró",
/// cuando services/http_sesion.dart cierra una sesión vencida).
///
/// v1.1 (mejora): se agrega isValidRut() y su chequeo antes de intentar
/// el login — antes solo se formateaba el RUT (guion + dígito
/// verificador visual) pero nunca se validaba que el dígito fuera
/// matemáticamente correcto, a diferencia del resto del sistema
/// (RegistroForm.jsx, GenerarQRCuidador.jsx en la web). Un RUT mal
/// tipeado ahora se detecta antes de gastar una llamada de red.
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/biometria_service.dart';
import '../services/storage_service.dart';
import 'activar_cuenta_screen.dart';
import 'dashboard_screen.dart';

String _normalizarRut(String raw) {
  final limpio = raw.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (limpio.length < 2) return limpio;
  final cuerpo = limpio.substring(0, limpio.length - 1);
  final dv = limpio[limpio.length - 1];
  return '$cuerpo-$dv';
}

bool _isValidRut(String rut) {
  final limpio = rut.replaceAll('.', '').replaceAll('-', '').trim().toUpperCase();
  if (limpio.length < 2) return false;
  final cuerpo = limpio.substring(0, limpio.length - 1);
  final dv = limpio.substring(limpio.length - 1);
  if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

  int suma = 0;
  int multiplo = 2;
  for (int i = cuerpo.length - 1; i >= 0; i--) {
    suma += int.parse(cuerpo[i]) * multiplo;
    multiplo = multiplo == 7 ? 2 : multiplo + 1;
  }
  final resto = 11 - (suma % 11);
  final dvEsperado = resto == 11 ? '0' : (resto == 10 ? 'K' : resto.toString());
  return dv == dvEsperado;
}

class LoginScreen extends StatefulWidget {
  final String? aviso;
  const LoginScreen({super.key, this.aviso});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  String? _error;
  bool _ocultarPassword = true;
  // Teléfono nuevo: código de 6 dígitos del correo
  String? _desafio;
  String? _emailCodigo;
  final _codigoController = TextEditingController();

  @override
  void dispose() {
    _rutController.dispose();
    _passwordController.dispose();
    _codigoController.dispose();
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
    if (!_isValidRut(rut)) {
      setState(() => _error = 'El RUT ingresado no es válido');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final r = await AuthService.login(rut, password);
      if (r.requiereCodigo) {
        _codigoController.clear();
        setState(() { _desafio = r.desafio; _emailCodigo = r.email; });
        return;
      }
      await _entrar();
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

  Future<void> _enviarCodigo() async {
    final codigo = _codigoController.text.replaceAll(RegExp(r'\D'), '');
    if (codigo.length != 6 || _desafio == null) {
      setState(() => _error = 'Escribe los 6 dígitos que llegaron a tu correo');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      await AuthService.loginCodigo(_desafio!, codigo);
      await _entrar();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        // Vencido o demasiados intentos: volver a la contraseña para pedir otro
        if (e.mensaje.contains('venció') || e.mensaje.contains('Demasiados')) _desafio = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo conectar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Sesión lista: registra el aviso push, ofrece la huella (una vez) y entra.
  Future<void> _entrar() async {
    // FcmService ya se inicializó en main(), pero en ese momento aún
    // no había sesión guardada, así que el token FCM real nunca
    // llegó al backend. Ahora que el login fue exitoso y hay un JWT
    // guardado, reintentamos el registro del token.
    await FcmService.registrarTokenSiHaySesion();
    await _ofrecerHuella();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _ofrecerHuella() async {
    if (await StorageService.biometriaActiva() != null) return;      // ya se le preguntó
    if ((await StorageService.obtenerLlave() ?? '').isEmpty) return;  // teléfono no vinculado
    if (!await BiometriaService.disponible()) return;
    if (!mounted) return;
    final quiere = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF1A3B8C)),
        title: const Text('¿Entrar con tu huella?'),
        content: const Text(
          'La próxima vez entras con tu huella (o el PIN de tu teléfono), sin escribir la contraseña. '
          'Si no usas la app por un rato, te la pediremos para proteger tu ficha.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Activar')),
        ],
      ),
    );
    if (quiere == true && await BiometriaService.autenticar(motivo: 'Confirma tu huella para activarla en MiSalud')) {
      await StorageService.guardarBiometria(true);
    } else {
      await StorageService.guardarBiometria(false);
    }
  }

  List<Widget> _camposCodigo() => [
        const Text(
          'Revisa tu correo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F235A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Estás entrando desde un teléfono nuevo. Te enviamos un código de 6 dígitos a '
          '${_emailCodigo ?? 'tu correo'}. Vale 10 minutos.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w600),
          onSubmitted: (_) => _enviarCodigo(),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F9B8E), width: 2),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _cargando ? null : _enviarCodigo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3B8C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _cargando
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cargando ? null : () => setState(() { _desafio = null; _error = null; }),
          child: const Text('No me llegó: volver a intentar'),
        ),
        const Text(
          'Revisa también la carpeta de spam. Este teléfono quedará como de confianza.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3B8C), Color(0xFF123566), Color(0xFF0B2E45)],
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
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/hypokratia_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HypokratIA',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
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
                      children: _desafio != null ? _camposCodigo() : [
                        const Text(
                          'Ingresa a tu cuenta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F235A)),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.aviso != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock_outlined, color: Color(0xFF92400E), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(widget.aviso!, style: const TextStyle(color: Color(0xFF92400E), fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextField(
                          controller: _rutController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onChanged: _onRutChanged,
                          decoration: InputDecoration(
                            labelText: 'RUT',
                            hintText: '12345678-9',
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0F9B8E)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0F9B8E), width: 2),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF0F9B8E)),
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
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F9B8E)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF0F9B8E), width: 2),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF0F9B8E)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF0F9B8E),
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
                              backgroundColor: const Color(0xFF1A3B8C),
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

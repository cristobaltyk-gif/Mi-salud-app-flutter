/// lib/screens/cambiar_clave_screen.dart — v1.0
///
/// Clave segura. Se muestra al entrar cuando el servidor responde
/// debe_cambiar_clave (la clave con que entró es débil o temporal).
///
/// Misma regla que el servidor (misalud-backend/seguridad_clave.py), que es
/// el que manda. Aquí solo se muestra en vivo: reglas que se ponen verdes,
/// barra de fuerza y 👁 para ver/ocultar. El botón queda inactivo hasta
/// cumplir todo y repetir la clave igual.
///
/// Al cambiarla, el servidor cierra todas las sesiones y quita los teléfonos
/// de confianza: se vuelve al login para entrar con la clave nueva.
library;

import 'package:flutter/material.dart';
import '../i18n/idioma.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

const int largoMinimoClave = 10;

const _comunes = {
  'password', 'contrasena', 'clave', 'claveclave', 'qwerty', 'qwertyuiop', 'asdfgh', 'zxcvbn',
  'abc123', '123456', '1234567890', 'admin', 'administrador', 'bienvenido', 'welcome', 'iloveyou',
  'teamo', 'hola', 'holahola', 'misalud', 'hipokratia', 'hypokratia', 'icarticular', 'chile',
  'medico', 'doctor', 'paciente', 'letmein', 'monkey', 'dragon', 'futbol', 'colocolo',
};

String _plano(String t) {
  const con = 'áéíóúüàèìòùâêîôûäëïöñÁÉÍÓÚÜÀÈÌÒÙÂÊÎÔÛÄËÏÖÑ';
  const sin = 'aeiouuaeiouaeiouaeionAEIOUUAEIOUAEIOUAEION';
  final b = StringBuffer();
  for (final c in t.split('')) {
    final i = con.indexOf(c);
    b.write(i >= 0 ? sin[i] : c);
  }
  return b.toString().toLowerCase();
}

class ReglaClave {
  final String texto;
  final bool ok;
  const ReglaClave(this.texto, this.ok);
}

List<ReglaClave> reglasClave(String clave, String? rut, List<String?> nombres) {
  final p = _plano(clave);
  final base = p.replaceAll(RegExp(r'[^a-z]'), '');
  final comun = _comunes.contains(base) ||
      ['123456', 'qwerty', 'password', 'contrasena'].any(p.contains);
  final cuerpoRut = (rut ?? '').split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
  final conRut = cuerpoRut.length >= 6 &&
      clave.replaceAll(RegExp(r'[^0-9]'), '').contains(cuerpoRut);
  final conNombre = nombres.any((n) => _plano(n ?? '')
      .split(RegExp(r'\s+'))
      .any((parte) => parte.length >= 3 && p.contains(parte)));
  return [
    ReglaClave(trp('Al menos {0} caracteres', [largoMinimoClave]), clave.length >= largoMinimoClave),
    ReglaClave(tr('Una mayúscula'), RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(clave)),
    ReglaClave(tr('Una minúscula'), RegExp(r'[a-záéíóúñ]').hasMatch(clave)),
    ReglaClave(tr('Un número'), RegExp(r'\d').hasMatch(clave)),
    ReglaClave(tr('Un carácter especial (! @ # \$ % …)'),
        RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑáéíóúñ]').hasMatch(clave)),
    ReglaClave(tr('No es una clave común ni contiene tu RUT o nombre'),
        clave.isNotEmpty && !comun && !conRut && !conNombre),
  ];
}

bool claveLista(String clave, String confirmar, String? rut, List<String?> nombres) =>
    reglasClave(clave, rut, nombres).every((r) => r.ok) && clave == confirmar;

class CambiarClaveScreen extends StatefulWidget {
  final String claveActual;
  final String? rut;
  final List<String?> nombres;
  const CambiarClaveScreen({super.key, required this.claveActual, this.rut, this.nombres = const []});

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  static const _teal = Color(0xFF0F9B8E);
  static const _navy = Color(0xFF0F235A);
  final _nueva = TextEditingController();
  final _repite = TextEditingController();
  bool _ocultar1 = true;
  bool _ocultar2 = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nueva.dispose();
    _repite.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      await AuthService.cambiarPassword(widget.claveActual, _nueva.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(aviso: tr('Tu clave se cambió. Entra con tu clave nueva.'))),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = tr('No se pudo conectar. Revisa tu conexión.'));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _salir() async {
    await AuthService.cerrarSesionServidor();
    await StorageService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  InputDecoration _deco(String label, bool ocultar, VoidCallback alternar) => InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: _teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 2),
        ),
        labelStyle: const TextStyle(color: _teal),
        suffixIcon: IconButton(
          icon: Icon(ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: ocultar ? tr('Ver clave') : tr('Ocultar clave'),
          onPressed: alternar,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final clave = _nueva.text;
    final reglas = reglasClave(clave, widget.rut, widget.nombres);
    final cumplidas = reglas.where((r) => r.ok).length;
    final int? nivel = clave.isEmpty
        ? null
        : cumplidas == reglas.length ? 4 : cumplidas >= 5 ? 3 : cumplidas >= 4 ? 2 : cumplidas >= 2 ? 1 : 0;
    final niveles = [
      (tr('Muy débil'), const Color(0xFFDC2626)),
      (tr('Débil'), const Color(0xFFEA580C)),
      (tr('Regular'), const Color(0xFFCA8A04)),
      (tr('Buena'), const Color(0xFF65A30D)),
      (tr('Segura'), const Color(0xFF16A34A)),
    ];
    final distinta = clave != widget.claveActual;
    final ok = claveLista(clave, _repite.text, widget.rut, widget.nombres) && distinta;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('Cambia tu clave'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
                      const SizedBox(height: 10),
                      Text(
                        tr('Por tu seguridad, tu clave actual ya no cumple las reglas de clave segura. Crea una nueva para seguir.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nueva,
                        obscureText: _ocultar1,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => setState(() => _error = null),
                        decoration: _deco(tr('Contraseña nueva'), _ocultar1,
                            () => setState(() => _ocultar1 = !_ocultar1)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 5,
                            margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: nivel != null && i <= nivel ? niveles[nivel].$2 : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        )),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 16,
                        child: Text(nivel != null ? niveles[nivel].$1 : '',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: nivel != null ? niveles[nivel].$2 : Colors.transparent)),
                      ),
                      const SizedBox(height: 6),
                      ...reglas.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              Icon(r.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 17, color: r.ok ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.texto, style: TextStyle(fontSize: 13,
                                  color: r.ok ? const Color(0xFF16A34A) : const Color(0xFF64748B)))),
                            ]),
                          )),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _repite,
                        obscureText: _ocultar2,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => setState(() => _error = null),
                        decoration: _deco(tr('Repite la contraseña'), _ocultar2,
                            () => setState(() => _ocultar2 = !_ocultar2)),
                      ),
                      if (_repite.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _repite.text == clave ? tr('✓ Las contraseñas coinciden') : tr('Las contraseñas no coinciden'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: _repite.text == clave ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                      ],
                      if (clave.isNotEmpty && !distinta) ...[
                        const SizedBox(height: 6),
                        Text(tr('La clave nueva debe ser distinta de la actual.'),
                            style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: ok && !_cargando ? _guardar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _cargando
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(tr('Cambiar clave'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _cargando ? null : _salir,
                        child: Text(tr('Salir'), style: const TextStyle(color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

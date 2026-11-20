// Idioma de la interfaz de MiSalud: es, en, de, fr.
// Se guarda en el teléfono; la primera vez se toma el idioma del teléfono.
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'textos.dart';

class Idioma {
  static const disponibles = {
    'es': 'Español',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
  };
  static const _clave = 'idioma_app';
  static final ValueNotifier<String> actual = ValueNotifier('es');

  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado != null && disponibles.containsKey(guardado)) {
        actual.value = guardado;
        return;
      }
    } catch (_) {}
    final tel = PlatformDispatcher.instance.locale.languageCode;
    actual.value = disponibles.containsKey(tel) ? tel : 'es';
  }

  static Future<void> poner(String codigo) async {
    if (!disponibles.containsKey(codigo)) return;
    actual.value = codigo;
    _redibujarTodo();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, codigo);
    } catch (_) {}
  }
}

/// Redibuja todas las pantallas abiertas (sin perder dónde estaba el usuario).
void _redibujarTodo() {
  final raiz = WidgetsBinding.instance.rootElement;
  if (raiz == null) return;
  void marcar(Element e) {
    e.markNeedsBuild();
    e.visitChildren(marcar);
  }
  raiz.visitChildren(marcar);
}

/// Traduce un texto de la interfaz escrito en español.
String tr(String es) {
  final l = Idioma.actual.value;
  if (l == 'es') return es;
  return textos[es]?[l] ?? es;
}

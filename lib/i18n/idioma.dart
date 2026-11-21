// Idioma de la interfaz de MiSalud: es, en, de, fr.
// Se elige UNA vez, la primera vez que se abre la app (es el idioma del país
// donde la persona vive y se atiende). Queda guardado; se vuelve a preguntar
// solo con "Olvidar este teléfono" o reinstalando la app.
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

  /// false hasta que la persona elige el idioma (primera apertura).
  static bool elegido = false;

  /// Idioma del teléfono, si está disponible (para dejarlo marcado al elegir).
  static String get delTelefono {
    final tel = PlatformDispatcher.instance.locale.languageCode;
    return disponibles.containsKey(tel) ? tel : 'es';
  }

  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado != null && disponibles.containsKey(guardado)) {
        actual.value = guardado;
        elegido = true;
        return;
      }
    } catch (_) {}
    elegido = false;
    actual.value = delTelefono;
  }

  /// Muestra la app en `codigo` mientras la persona elige (sin guardar).
  static void probar(String codigo) {
    if (!disponibles.containsKey(codigo)) return;
    actual.value = codigo;
    _redibujarTodo();
  }

  /// Guarda el idioma elegido en la primera apertura.
  static Future<void> elegir(String codigo) async {
    if (!disponibles.containsKey(codigo)) return;
    actual.value = codigo;
    elegido = true;
    _redibujarTodo();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, codigo);
    } catch (_) {}
  }

  /// "Olvidar este teléfono": la próxima vez se vuelve a preguntar.
  static Future<void> olvidar() async {
    elegido = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
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

/// Traduce un texto con datos al medio: trp('Agendar para {0}', [nombre]).
String trp(String es, List<Object?> valores) {
  var t = tr(es);
  for (var i = 0; i < valores.length; i++) {
    t = t.replaceAll('{$i}', '${valores[i] ?? ''}');
  }
  return t;
}

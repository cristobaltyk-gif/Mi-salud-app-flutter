/// lib/services/traduccion_service.dart — v1.0
///
/// Traduce el CONTENIDO de la ficha (diagnósticos, atenciones, recetas,
/// indicaciones, antecedentes) EN EL TELÉFONO, sin internet: ML Kit de
/// Google (traducción automática que corre dentro del teléfono, no IA
/// generativa; nada sale del teléfono).
///
/// Para que funcione en el extranjero sin red, los idiomas se bajan antes
/// (≈30 MB cada uno) con Wi-Fi: prepararIdiomas() se llama sola al abrir la
/// ficha con internet.
///
/// La traducción es una AYUDA para el médico: el original en español sigue
/// siendo el registro clínico y siempre se puede ver.
library;

import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../i18n/idioma.dart';

class TraduccionService {
  /// Idiomas para el médico, además del español
  static const Map<String, TranslateLanguage> idiomas = {
    'en': TranslateLanguage.english,
    'de': TranslateLanguage.german,
    'fr': TranslateLanguage.french,
  };

  static bool _preparando = false;

  /// Baja (solo con Wi-Fi) los modelos que falten: español + en/de/fr.
  static Future<void> prepararIdiomas() async {
    if (_preparando) return;
    _preparando = true;
    try {
      final m = OnDeviceTranslatorModelManager();
      for (final l in [TranslateLanguage.spanish, ...idiomas.values]) {
        try {
          if (!await m.isModelDownloaded(l.bcpCode)) {
            await m.downloadModel(l.bcpCode, isWifiRequired: true);
          }
        } catch (_) {}
      }
    } finally {
      _preparando = false;
    }
  }

  /// ¿Está el idioma listo para traducir sin internet?
  static Future<bool> listo(String idioma) async {
    final l = idiomas[idioma];
    if (l == null) return false;
    final m = OnDeviceTranslatorModelManager();
    return await m.isModelDownloaded(TranslateLanguage.spanish.bcpCode) && await m.isModelDownloaded(l.bcpCode);
  }

  /// Devuelve una COPIA de la ficha con los textos clínicos traducidos.
  /// Nombres, RUT, fechas y códigos no se tocan.
  static Future<Map<String, dynamic>> traducirFicha(Map<String, dynamic> ficha, String idioma) async {
    final destino = idiomas[idioma];
    if (destino == null) throw Exception(tr('Idioma no disponible'));
    if (!await listo(idioma)) {
      throw Exception(tr('El idioma no está descargado en el teléfono (se baja solo con Wi-Fi)'));
    }
    final t = OnDeviceTranslator(sourceLanguage: TranslateLanguage.spanish, targetLanguage: destino);
    final cache = <String, String>{};
    Future<String> trad(dynamic v) async {
      final s = (v ?? '').toString();
      if (s.trim().isEmpty) return s;
      return cache[s] ??= await _traducirTexto(t, s);
    }

    try {
      final copia = _copia(ficha) as Map<String, dynamic>;
      final p = copia['paciente'];
      if (p is Map) {
        for (final k in ['sexo', 'prevision']) {
          if (p[k] is String) p[k] = await trad(p[k]);
        }
      }
      for (final lista in [copia['eventos'], copia['eventos_con_indicaciones']]) {
        if (lista is! List) continue;
        for (final e in lista) {
          if (e is! Map) continue;
          for (final k in ['diagnostico', 'especialidad', 'tipo', 'indicaciones']) {
            if (e[k] is String) e[k] = await trad(e[k]);
          }
          final c = e['contenido'];
          if (c is Map) {
            for (final k in [
              'atencion', 'diagnostico', 'receta', 'examenes', 'indicaciones',
              'orden_kinesiologia', 'indicacion_quirurgica', 'evolucion',
            ]) {
              if (c[k] is String) c[k] = await trad(c[k]);
            }
          }
        }
      }
      final ant = copia['antecedentes'];
      if (ant is Map) {
        for (final lista in ant.values) {
          if (lista is! List) continue;
          for (final a in lista) {
            if (a is Map && a['descripcion'] is String) a['descripcion'] = await trad(a['descripcion']);
          }
        }
      }
      final rec = copia['recordatorios'];
      if (rec is List) {
        for (final r in rec) {
          if (r is! Map) continue;
          for (final k in ['dosis', 'indicaciones', 'notas']) {
            if (r[k] is String) r[k] = await trad(r[k]);
          }
        }
      }
      copia['idioma'] = idioma;
      return copia;
    } finally {
      await t.close();
    }
  }

  /// Por líneas (mantiene saltos de línea y no excede el largo que acepta ML Kit).
  static Future<String> _traducirTexto(OnDeviceTranslator t, String texto) async {
    final salida = <String>[];
    for (final linea in texto.split('\n')) {
      if (linea.trim().isEmpty) {
        salida.add(linea);
        continue;
      }
      salida.add(await t.translateText(linea));
    }
    return salida.join('\n');
  }

  static dynamic _copia(dynamic v) {
    if (v is Map) return {for (final e in v.entries) e.key.toString(): _copia(e.value)};
    if (v is List) return [for (final x in v) _copia(x)];
    return v;
  }
}

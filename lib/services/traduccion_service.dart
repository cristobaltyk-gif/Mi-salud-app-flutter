/// lib/services/traduccion_service.dart — v1.1
///
/// v1.1: usa primero la traducción hecha con IA (Claude) que viene dentro de la
/// copia cifrada; ML Kit solo para lo que falte.
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

  /// Devuelve una COPIA de la ficha con los textos clínicos traducidos, para
  /// mostrársela al médico. Nombres, RUT, fechas y códigos no se tocan.
  ///
  /// Primero usa la traducción que viene DENTRO de la copia cifrada
  /// (ficha['traducciones'][idioma], hecha con Claude en el servidor mientras
  /// hubo internet: mejor con lenguaje médico). Lo que no esté ahí lo traduce
  /// ML Kit en el teléfono, si el idioma está descargado; si no, queda en
  /// español (el médico siempre puede ver el original).
  /// Los errores van en español: la página del médico los muestra en su idioma.
  static Future<Map<String, dynamic>> traducirFicha(Map<String, dynamic> ficha, String idioma) async {
    final destino = idiomas[idioma];
    if (destino == null) throw Exception('Idioma no disponible');
    final todas = ficha['traducciones'];
    final dic = <String, String>{};
    if (todas is Map && todas[idioma] is Map) {
      (todas[idioma] as Map).forEach((k, v) {
        if (k is String && v is String) dic[k] = v;
      });
    }
    final mlkit = await listo(idioma);
    if (dic.isEmpty && !mlkit) {
      throw Exception('El idioma no está descargado en el teléfono (se baja solo con Wi-Fi)');
    }
    final t = mlkit ? OnDeviceTranslator(sourceLanguage: TranslateLanguage.spanish, targetLanguage: destino) : null;
    final cache = <String, String>{};
    var deClaude = 0, deMlkit = 0;
    Future<String> trad(dynamic v) async {
      final s = (v ?? '').toString();
      if (s.trim().isEmpty) return s;
      final hecha = dic[s];
      if (hecha != null) {
        deClaude++;
        return hecha;
      }
      if (t == null) return s;
      deMlkit++;
      return cache[s] ??= await _traducirTexto(t, s);
    }

    try {
      final copia = sinTraducciones(_copia(ficha) as Map<String, dynamic>);
      final p = copia['paciente'];
      if (p is Map) {
        for (final k in camposPaciente) {
          if (p[k] is String) p[k] = await trad(p[k]);
        }
      }
      for (final lista in [copia['eventos'], copia['eventos_con_indicaciones']]) {
        if (lista is! List) continue;
        for (final e in lista) {
          if (e is! Map) continue;
          for (final k in camposEvento) {
            if (e[k] is String) e[k] = await trad(e[k]);
          }
          final c = e['contenido'];
          if (c is Map) {
            for (final k in camposContenido) {
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
          for (final k in camposRecordatorio) {
            if (r[k] is String) r[k] = await trad(r[k]);
          }
        }
      }
      copia['idioma'] = idioma;
      // Para el aviso de la página: 'ia' (Claude), 'telefono' (ML Kit) o 'mixta'
      copia['traduccion_fuente'] = deMlkit == 0 ? 'ia' : (deClaude == 0 ? 'telefono' : 'mixta');
      return copia;
    } finally {
      await t?.close();
    }
  }

  /// Mismos campos que traduce el servidor (misalud-backend services/traduccion_clinica.py)
  static const camposPaciente = ['sexo', 'prevision'];
  static const camposEvento = ['diagnostico', 'especialidad', 'tipo', 'indicaciones'];
  static const camposContenido = [
    'atencion', 'diagnostico', 'receta', 'examenes', 'indicaciones',
    'orden_kinesiologia', 'indicacion_quirurgica', 'evolucion',
    'examen_fisico', 'examen_clinico_bucal', 'plan_tratamiento',
    'procedimiento_enfermeria', 'piezas_tratadas', 'signos_vitales',
  ];
  static const camposRecordatorio = ['dosis', 'indicaciones', 'notas'];

  /// La ficha que se envía al médico, sin el diccionario de traducciones
  /// (no lo necesita y pesa).
  static Map<String, dynamic> sinTraducciones(Map<String, dynamic> ficha) {
    if (!ficha.containsKey('traducciones')) return ficha;
    return Map<String, dynamic>.of(ficha)..remove('traducciones');
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

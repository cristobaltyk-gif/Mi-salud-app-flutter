/// lib/services/traduccion_service.dart — v1.2
///
/// Traduce la ficha SOLO para el médico (lector en el PC / página por la red
/// del teléfono), SOLO a su idioma y SOLO cuando la lee. No se guarda ninguna
/// ficha traducida: la ficha es una, en su idioma original. El paciente nunca
/// ve esto (en la app ve su explicación con IA, en su idioma).
///
/// De dónde sale la traducción, en este orden:
/// 1. Resumen (antecedentes): viene ya traducido con IA dentro de la copia
///    cifrada (ficha['resumen_traducido'][idioma]); sirve aun sin internet.
/// 2. Con red: el resto se traduce al instante con IA (Claude) en el servidor
///    (POST /api/copia/traducir; no se guarda nada).
/// 3. Sin red, o si falla: ML Kit en el teléfono (sin internet, de menor
///    calidad con lenguaje médico). Los idiomas se bajan antes con Wi-Fi:
///    prepararIdiomas() se llama sola al abrir la ficha con internet.
/// Lo que no se pueda traducir queda en el original; el médico siempre puede
/// ver el original.
///
/// Los errores van en español: la página del médico los muestra en su idioma.
library;

import 'dart:convert';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../config/app_config.dart';
import 'http_sesion.dart' as http;
import 'storage_service.dart';

class TraduccionService {
  /// Idiomas para el médico, además del español
  static const Map<String, TranslateLanguage> idiomas = {
    'en': TranslateLanguage.english,
    'de': TranslateLanguage.german,
    'fr': TranslateLanguage.french,
  };

  /// Mismos campos que se muestran al médico
  static const camposPaciente = ['sexo', 'prevision'];
  static const camposEvento = ['diagnostico', 'especialidad', 'tipo', 'indicaciones'];
  static const camposContenido = [
    'atencion', 'diagnostico', 'receta', 'examenes', 'indicaciones',
    'orden_kinesiologia', 'indicacion_quirurgica', 'evolucion',
    'examen_fisico', 'examen_clinico_bucal', 'plan_tratamiento',
    'procedimiento_enfermeria', 'piezas_tratadas', 'signos_vitales',
  ];
  static const camposRecordatorio = ['dosis', 'indicaciones', 'notas'];

  static bool _preparando = false;

  /// Qué pasó con la traducción por IA en el último intento (para diagnosticar)
  static String _estadoIa = '-';

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

  /// ¿Está el idioma listo para traducir sin internet (ML Kit)?
  static Future<bool> listo(String idioma) async {
    final l = idiomas[idioma];
    if (l == null) return false;
    final m = OnDeviceTranslatorModelManager();
    return await m.isModelDownloaded(TranslateLanguage.spanish.bcpCode) && await m.isModelDownloaded(l.bcpCode);
  }

  /// La ficha que se le envía al médico, sin el resumen traducido a otros
  /// idiomas (no lo necesita: se usa al traducir).
  static Map<String, dynamic> sinTraducciones(Map<String, dynamic> ficha) {
    if (!ficha.containsKey('resumen_traducido')) return ficha;
    return Map<String, dynamic>.of(ficha)..remove('resumen_traducido');
  }

  /// Devuelve una COPIA de la ficha con los textos clínicos en el idioma del
  /// médico (solo para mostrar). Nombres, RUT, fechas y códigos no se tocan.
  static Future<Map<String, dynamic>> traducirFicha(Map<String, dynamic> ficha, String idioma) async {
    final destino = idiomas[idioma];
    if (destino == null) throw Exception('Idioma no disponible');

    final copia = sinTraducciones(_copia(ficha) as Map<String, dynamic>);

    // 1. Resumen ya traducido (antecedentes)
    final resumen = <String, String>{};
    final rt = ficha['resumen_traducido'];
    if (rt is Map && rt[idioma] is Map) {
      (rt[idioma] as Map).forEach((k, v) {
        if (k is String && v is String) resumen[k] = v;
      });
    }

    // Textos a mostrar traducidos
    final textos = <String>{};
    _recorrer(copia, (s) {
      if (s.trim().isNotEmpty) textos.add(s);
      return s;
    });

    final hecho = <String, String>{};
    var deIa = 0, deTelefono = 0;
    for (final s in textos) {
      final r = resumen[s];
      if (r != null) {
        hecho[s] = r;
        deIa++;
      }
    }

    // 2. Con red: IA al instante (no se guarda nada)
    final faltan = textos.where((s) => !hecho.containsKey(s)).toList();
    _estadoIa = 'sin red';
    if (faltan.isNotEmpty && await http.hayInternet()) {
      final rut = ((ficha['paciente'] as Map?)?['rut'] ?? '').toString();
      final ia = await _traducirConIa(faltan, idioma, rut);
      hecho.addAll(ia);
      deIa += ia.length;
    }

    // 3. Sin red o si faltó algo: ML Kit en el teléfono. Si ML Kit falla,
    //    esos textos quedan en el original (nunca se cae toda la traducción).
    final quedan = textos.where((s) => !hecho.containsKey(s)).toList();
    String? errorTelefono;
    if (quedan.isNotEmpty) {
      if (await listo(idioma)) {
        OnDeviceTranslator? t;
        try {
          t = OnDeviceTranslator(sourceLanguage: TranslateLanguage.spanish, targetLanguage: destino);
          for (final s in quedan) {
            hecho[s] = await _traducirTexto(t, s);
            deTelefono++;
          }
        } catch (e) {
          errorTelefono = e.toString();
        } finally {
          try {
            await t?.close();
          } catch (_) {}
        }
      } else {
        errorTelefono = 'idioma no descargado';
      }
    }
    if (hecho.isEmpty && textos.isNotEmpty) {
      // Nada se pudo traducir: el médico ve el original. El detalle ayuda a
      // saber qué falló (IA y teléfono).
      throw Exception('El teléfono no pudo traducir (IA: $_estadoIa; teléfono: ${errorTelefono ?? '-'})');
    }

    _recorrer(copia, (s) => hecho[s] ?? s);
    copia['idioma'] = idioma;
    // Para el aviso de la página: 'ia', 'telefono' o 'mixta'
    copia['traduccion_fuente'] = deTelefono == 0 ? 'ia' : (deIa == 0 ? 'telefono' : 'mixta');
    // Textos que quedaron en el original (falló la IA y el teléfono para esos)
    copia['traduccion_incompleta'] = textos.length - hecho.length;
    return copia;
  }

  /// Pide la traducción al servidor por partes. Devuelve {original: traducción}.
  /// Si el paciente se opuso al uso de IA, el servidor responde 403 y todo se
  /// traduce con ML Kit (no sale del teléfono).
  static Future<Map<String, String>> _traducirConIa(List<String> textos, String idioma, String rutPaciente) async {
    final salida = <String, String>{};
    final token = await StorageService.obtenerToken();
    if (token == null || token.isEmpty) {
      _estadoIa = 'sin sesión';
      return salida;
    }
    _estadoIa = 'sin respuesta';
    var i = 0;
    while (i < textos.length) {
      final parte = <String>[];
      var largo = 0;
      while (i < textos.length && parte.length < 300 && (parte.isEmpty || largo + textos[i].length <= 120000)) {
        largo += textos[i].length;
        parte.add(textos[i++]);
      }
      try {
        final r = await http
            .post(
              Uri.parse(AppConfig.copiaTraducirEndpoint),
              headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
              body: jsonEncode({
                'idioma': idioma,
                if (rutPaciente.isNotEmpty) 'rut_paciente': rutPaciente,
                'textos': parte,
              }),
            )
            .timeout(const Duration(seconds: 150));
        if (r.statusCode == 403) {
          _estadoIa = 'el paciente no permite IA (403)';
          break; // sin permiso de IA: el resto con ML Kit
        }
        if (r.statusCode != 200) {
          _estadoIa = 'servidor ${r.statusCode}';
          continue;
        }
        final lista = (jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>)['textos'];
        if (lista is! List || lista.length != parte.length) continue;
        for (var k = 0; k < parte.length; k++) {
          final v = lista[k];
          if (v is String && v.isNotEmpty) salida[parte[k]] = v;
        }
        _estadoIa = 'ok';
      } catch (e) {
        _estadoIa = 'error: $e'; // ese trozo lo traduce ML Kit
      }
    }
    return salida;
  }

  /// Aplica `f` a cada texto clínico de la ficha (y lo reemplaza por su resultado).
  static void _recorrer(Map<String, dynamic> ficha, String Function(String) f) {
    void campos(Map m, List<String> ks) {
      for (final k in ks) {
        if (m[k] is String) m[k] = f(m[k] as String);
      }
    }

    final p = ficha['paciente'];
    if (p is Map) campos(p, camposPaciente);
    for (final lista in [ficha['eventos'], ficha['eventos_con_indicaciones']]) {
      if (lista is! List) continue;
      for (final e in lista) {
        if (e is! Map) continue;
        campos(e, camposEvento);
        final c = e['contenido'];
        if (c is Map) campos(c, camposContenido);
      }
    }
    final ant = ficha['antecedentes'];
    if (ant is Map) {
      for (final lista in ant.values) {
        if (lista is! List) continue;
        for (final a in lista) {
          if (a is Map) campos(a, const ['descripcion']);
        }
      }
    }
    final rec = ficha['recordatorios'];
    if (rec is List) {
      for (final r in rec) {
        if (r is Map) campos(r, camposRecordatorio);
      }
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

"""
Segunda pasada de traducción: envuelve los textos visibles que quedaron fuera
de envolver.py, incluidos los textos con datos al medio.

  'Hola'                      -> tr('Hola')
  'Agendar para ${x}'         -> trp('Agendar para {0}', [x])
  'a ' 'b'  (concatenados)    -> tr('a ' 'b')

Salta claves de mapas, comparaciones, cabeceras HTTP, expresiones regulares,
URLs, logs y las tablas `const` (esas se traducen donde se muestran).
Uso: python herramientas/i18n/envolver2.py [--aplicar]
Imprime JSON con las claves nuevas en /tmp/claves2.json.
"""
import os, re, sys, json

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
# Toma scanner_quitar_const de envolver.py sin ejecutar ese script
_src_env = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "envolver.py"), encoding="utf-8").read()
exec(_src_env[_src_env.index("def scanner_quitar_const"):_src_env.index("nuevas = {}")])

ARCHIVOS_EXCLUIDOS = {
    "lib/config/app_config.dart", "lib/services/fcm_service.dart",
    "lib/web/atencion_pagina.dart", "lib/services/direccion_service.dart",
}
PREV_EXCLUIR = re.compile(
    r"(==|!=|\.contains\(|\.startsWith\(|\.endsWith\(|replaceFirst\(|replaceAll\(|RegExp\(|"
    r"DateFormat\(|getLocation\(|headers\.set\(|\blog\(|\bprint\(|debugPrint\(|FormatException\(|"
    r"_pasoInicio\(|\bcase|AndroidInitializationSettings\(|addJavaScriptChannel\(|Uri\.parse\(|"
    r"File\(|fontFamily:|nombreMostrar:|label:|_responder\(res, \d+, \{|\btr\(|\btrp\(|'detail':|"
    r"nombre_dispositivo'?:|setString\(|getString\()\s*$")
PALABRA_SUELTA_OK = re.compile(r"^[¿¡]?[A-ZÁÉÍÓÚÑ][a-záéíóúñü]+[.!?…:]?$")
EXCLUIR_TEXTOS = {"Firebase", "Roboto", "MiSalud", "HypokratiaApp", "Authorization", "No hay sesión activa",
                  "Recordatorio", "Teléfono Android", "Teléfono", "Cuenta no activada", "HypokratIA", "PDF"}
# Cadenas que deben seguir en español (las usa otra parte del código como clave)
LINEAS_EXCLUIDAS = {
    ("lib/services/agenda_service.dart", r) for r in range(190, 210)
} | {("lib/widgets/etiqueta_especialidad.dart", r) for r in range(10, 25)} \
  | {("lib/screens/historial_consultas_cuidado_screen.dart", r) for r in range(136, 152)} \
  | {("lib/screens/ficha_screen.dart", r) for r in range(626, 635)} \
  | {("lib/screens/agendar_screen.dart", r) for r in range(289, 306)} \
  | {("lib/services/agenda_service.dart", 188), ("lib/services/biometria_service.dart", 35),
     ("lib/screens/reserva_web_screen.dart", 113), ("lib/screens/dashboard_screen.dart", 467),
     ("lib/screens/direccion_screen.dart", 139)}
# Textos con plurales o frases anidadas: se arreglan a mano
MANUALES = {("lib/screens/ficha_tab_cuidado.dart", 150), ("lib/screens/tab_cotizador_cuidado.dart", 103),
            ("lib/screens/cotizador_screen.dart", 130), ("lib/screens/ficha_screen.dart", 581),
            ("lib/screens/cuidador_screen.dart", 586), ("lib/screens/cuidador_screen.dart", 511),
            ("lib/screens/cuidador_screen.dart", 227), ("lib/screens/agendar_screen.dart", 495),
            ("lib/screens/recordatorios_tab_unificada.dart", 298), ("lib/screens/recordatorios_tab_cuidado.dart", 110),
            ("lib/screens/compartir_ficha_cuidado_screen.dart", 269), ("lib/widgets/firma_terminos.dart", 80)}
LINEAS_EXCLUIDAS |= MANUALES


def leer_literal(src, i):
    """Lee un literal Dart desde src[i]. Devuelve (fin, raw, partes) donde partes es una
    lista de ('t', texto) o ('e', expresion)."""
    raw = False
    if src[i] == "r":
        raw = True; i += 1
    q = src[i:i+3] if src[i:i+3] in ("'''", '"""') else src[i]
    j = i + len(q)
    partes, buf = [], []
    n = len(src)
    while j < n and not src.startswith(q, j):
        c = src[j]
        if c == "\\" and not raw:
            buf.append(src[j:j+2]); j += 2; continue
        if c == "$" and not raw:
            if src[j+1:j+2] == "{":
                if buf: partes.append(("t", "".join(buf))); buf = []
                k = j + 2; prof = 1
                while k < n and prof:
                    if src[k] in "'\"":
                        k2 = leer_literal(src, k)[0]; k = k2; continue
                    if src[k] == "{": prof += 1
                    elif src[k] == "}": prof -= 1
                    k += 1
                partes.append(("e", src[j+2:k-1])); j = k; continue
            m = re.match(r"[A-Za-z_]\w*", src[j+1:])
            if m:
                if buf: partes.append(("t", "".join(buf))); buf = []
                partes.append(("e", m.group(0))); j += 1 + len(m.group(0)); continue
        buf.append(c); j += 1
    if buf: partes.append(("t", "".join(buf)))
    return j + len(q), raw, partes, q


def grupos(src):
    """Encuentra grupos de literales adyacentes fuera de comentarios."""
    i, n = 0, len(src)
    res = []
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i); i = n if j < 0 else j; continue
        if src.startswith("/*", i):
            j = src.find("*/", i); i = n if j < 0 else j + 2; continue
        c = src[i]
        es_raw = c == "r" and src[i+1:i+2] in ("'", '"') and not re.match(r"\w", src[i-1:i] or " ")
        if c in "'\"" or es_raw:
            ini = i
            lits = []
            while True:
                fin, raw, partes, q = leer_literal(src, i)
                lits.append((i, fin, raw, partes, q))
                k = fin
                while k < n and src[k] in " \t\n": k += 1
                if k < n and (src[k] in "'\"" or (src[k] == "r" and src[k+1:k+2] in "'\"")):
                    i = k; continue
                break
            res.append((ini, lits[-1][1], lits))
            i = lits[-1][1]; continue
        i += 1
    return res


def clave_y_exprs(lits):
    clave, exprs = [], []
    for (_, _, raw, partes, q) in lits:
        for tipo, v in partes:
            if tipo == "t": clave.append(v)
            else:
                clave.append("{%d}" % len(exprs)); exprs.append(v)
    return "".join(clave), exprs


def es_candidato(clave, lits):
    if any(l[2] for l in lits) or any(l[4] in ("'''", '"""') for l in lits): return False
    sin = re.sub(r"\{\d+\}", "", clave)
    if not re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{3,}", sin): return False
    if sin.strip() in EXCLUIR_TEXTOS: return False
    if re.match(r"\s*(https?:|/|assets|package:|data:|@|Bearer|WIFI:|\$|&|\?)", clave): return False
    if " " not in sin.strip():
        s = sin.strip()
        # palabra suelta: solo si parece texto (Mayúscula inicial o con emoji al inicio)
        s2 = re.sub(r"^[^\wÁÉÍÓÚáéíóúñÑ¿¡]+\s*", "", s)
        if not PALABRA_SUELTA_OK.match(s2): return False
    return True


def dart_lit(t):
    return "'" + t.replace("'", "\\'") + "'" if "'" not in t or "\\'" in t else '"' + t + '"'


def procesar(ruta_rel, aplicar):
    p = os.path.join(RAIZ, ruta_rel)
    src = open(p, encoding="utf-8").read()
    nuevas = {}
    reemplazos = []
    for ini, fin, lits in grupos(src):
        linea = src.count("\n", 0, ini) + 1
        if (ruta_rel, linea) in LINEAS_EXCLUIDAS: continue
        antes = src[max(0, ini-60):ini]
        if PREV_EXCLUIR.search(antes): continue
        # clave de mapa: 'x': ...  precedido de { , (
        k = fin
        while k < len(src) and src[k] in " \t": k += 1
        a = antes.rstrip()
        if src[k:k+1] == ":" and a[-1:] in ("{", ",", "(") : continue
        clave, exprs = clave_y_exprs(lits)
        if not es_candidato(clave, lits): continue
        if ruta_rel.startswith("lib/services/") and "sesión" in clave: continue
        original = src[ini:fin]
        if exprs:
            # el texto de la clave sin escapes de $
            nuevo = "trp(" + "'" + clave.replace("'", "\\'") + "'" + ", [" + ", ".join(e.strip() for e in exprs) + "])"
        else:
            nuevo = "tr(" + original + ")"
        reemplazos.append((ini, fin, nuevo, clave, linea))
    if not reemplazos: return {}, []
    out, ult = [], 0
    for ini, fin, nuevo, clave, linea in reemplazos:
        out.append(src[ult:ini]); out.append(nuevo); ult = fin
        nuevas[clave] = f"{ruta_rel}:{linea}"
    out.append(src[ult:])
    nuevo_src = "".join(out)
    posiciones = [m.start() for m in re.finditer(r"\btrp?\(", nuevo_src)]
    nuevo_src = scanner_quitar_const(nuevo_src, posiciones)
    if "i18n/idioma.dart" not in nuevo_src:
        prof = ruta_rel.count("/") - 1
        imp = "../" * prof + "i18n/idioma.dart"
        nuevo_src = re.sub(r"^(import [^\n]+\n)", r"\1import '" + imp + "';\n", nuevo_src, count=1, flags=re.M)
    if aplicar:
        open(p, "w", encoding="utf-8").write(nuevo_src)
    return nuevas, reemplazos


if __name__ == "__main__":
    aplicar = "--aplicar" in sys.argv
    todas = {}
    for d, _, fs in os.walk(os.path.join(RAIZ, "lib")):
        for f in sorted(fs):
            if not f.endswith(".dart"): continue
            rel = os.path.relpath(os.path.join(d, f), RAIZ)
            if rel in ARCHIVOS_EXCLUIDOS or rel.startswith("lib/i18n/"): continue
            nuevas, _ = procesar(rel, aplicar)
            todas.update(nuevas)
    json.dump(todas, open("/tmp/claves2.json", "w"), ensure_ascii=False, indent=1)
    for k, v in todas.items(): print(v, "|", k)
    print(len(todas), "claves", file=sys.stderr)

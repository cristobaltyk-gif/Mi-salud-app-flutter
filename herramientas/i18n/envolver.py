"""
Envuelve los textos visibles de la app en tr('...') para traducirlos
(lib/i18n/). Solo toca textos en contextos de interfaz: Text('...'),
labelText:, hintText:, helperText:, tooltip:, title: '...', message:.
Quita el `const` de los constructores que encierran un tr(...) (ya no son
constantes). Idempotente: no vuelve a envolver lo ya envuelto.
Uso: python herramientas/i18n/envolver.py  → imprime las cadenas nuevas.
"""
import os, re, json, sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
CARPETAS = ["lib/screens", "lib/widgets"]
CTX = re.compile(r"(\bText\(\s*|\b(?:labelText|hintText|helperText|tooltip|message|semanticLabel|errorText|title)\s*:\s*)'((?:[^'\\\n$]|\\.)*)'")

def es_texto(t):
    return bool(re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{2}", t)) and not re.match(r"(https?:|/|assets)", t)

def scanner_quitar_const(src, posiciones):
    """Quita 'const ' de los constructores/listas cuyo paréntesis encierra alguna posición."""
    pila = []  # (pos_apertura, pos_const o None)
    quitar = set()
    i, n = 0, len(src)
    objetivos = sorted(posiciones)
    k = 0
    while i < n:
        while k < len(objetivos) and objetivos[k] <= i:
            for _, pc in pila:
                if pc is not None: quitar.add(pc)
            k += 1
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i); i = n if j < 0 else j; continue
        if src.startswith("/*", i):
            j = src.find("*/", i); i = n if j < 0 else j + 2; continue
        if c in "'\"":
            triple = src[i:i+3] in ("'''", '"""')
            q = src[i:i+3] if triple else c
            j = i + len(q)
            while j < n and not src.startswith(q, j):
                j += 2 if src[j] == "\\" else 1
            i = j + len(q); continue
        if c in "([{":
            # ¿hay 'const' antes del identificador/genérico que precede?
            j = i - 1
            while j >= 0 and src[j] in " \t\n": j -= 1
            m = re.search(r"(const\s+)([A-Za-z_][\w.]*(<[^()]*>)?\s*)?$", src[max(0, j-120):j+1])
            pc = None
            if m and m.group(1):
                inicio = max(0, j-120) + m.start(1)
                antes = src[max(0, inicio-8):inicio]
                if not re.search(r"(static|=)\s*$", antes):
                    pc = inicio
            pila.append((i, pc))
        elif c in ")]}":
            if pila: pila.pop()
        i += 1
    for pc in sorted(quitar, reverse=True):
        src = src[:pc] + src[pc+len("const"):].lstrip(" ") if src[pc:pc+5] == "const" else src
    return src

nuevas = {}
for carpeta in CARPETAS:
    for d, _, fs in os.walk(os.path.join(RAIZ, carpeta)):
        for f in fs:
            if not f.endswith(".dart"): continue
            p = os.path.join(d, f)
            src = open(p, encoding="utf-8").read()
            posiciones, out, ult = [], [], 0
            for m in CTX.finditer(src):
                t = m.group(2)
                if not es_texto(t): continue
                ini = m.start(2) - 1
                out.append(src[ult:ini])
                out.append("tr('" + t + "')")
                ult = m.end(2) + 1
                nuevas[t] = os.path.relpath(p, RAIZ)
            if not out: continue
            out.append(src[ult:])
            nuevo = "".join(out)
            posiciones = [m.start() for m in re.finditer(r"\btr\('", nuevo)]
            nuevo = scanner_quitar_const(nuevo, posiciones)
            if "i18n/idioma.dart" not in nuevo:
                rel = os.path.relpath(os.path.join(RAIZ, "lib/i18n/idioma.dart"), d).replace(os.sep, "/")
                nuevo = re.sub(r"^(import [^\n]+\n)", r"\1import '" + rel + "';\n", nuevo, count=1, flags=re.M)
            open(p, "w", encoding="utf-8").write(nuevo)
json.dump(nuevas, open("/tmp/nuevas.json", "w"), ensure_ascii=False, indent=0)
print(len(nuevas))

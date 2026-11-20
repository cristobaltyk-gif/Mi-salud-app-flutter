"""
Arma la página de atención que ve el médico en las consultas sin internet,
a partir de la pantalla "Atención Clínica" de la Ficha:
  · ficha-dashboard-atencion.css  copia de Ficha-cl-nica-ica-fronted/styles/atencion/dashboard-atencion.css
  · cuerpo.html / app.js / extra.css  la misma estructura en HTML simple (sin dictado ni Claude)
Genera:
  · lib/web/atencion_pagina.dart          (red del teléfono, QR)
  · herramientas/lector_pc/atencion.html  (Lector HypokratIA en el PC)
Uso: python herramientas/pagina_atencion/generar.py
"""
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
leer = lambda n: open(os.path.join(AQUI, n), encoding="utf-8").read()

css = leer("ficha-dashboard-atencion.css") + leer("extra.css")
base = ('<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>HypokratIA · Atención Clínica</title><style>' + css + '</style></head><body>'
        + leer("cuerpo.html") + '<script>' + leer("i18n.js") + '\n' + leer("app.js") + '</script></body></html>')
assert "'''" not in base

dart = ('/// lib/web/atencion_pagina.dart — GENERADO por herramientas/pagina_atencion/generar.py\n'
        '///\n/// Página de atención que ve el profesional en una consulta sin conexión:\n'
        '/// la misma pantalla "Atención Clínica" de la Ficha, sin dictado ni Claude.\n'
        "library;\n\nconst String atencionPagina = r'''" + base + "''';\n")
open(os.path.join(RAIZ, "lib/web/atencion_pagina.dart"), "w", encoding="utf-8").write(dart)

# ── Lector PC: + espera / solicitud con código / terminar ──
espera = '''
<div class="hk-capa" id="espera">
  <div class="hk-tarjeta">
    <div class="hk-idiomas"><button data-l="es" onclick="ponerIdioma('es')">ES</button><button data-l="en" onclick="ponerIdioma('en')">EN</button><button data-l="de" onclick="ponerIdioma('de')">DE</button><button data-l="fr" onclick="ponerIdioma('fr')">FR</button></div>
    <div class="hk-tarjeta-icono"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg></div>
    <p class="hk-tarjeta-titulo" data-i="espera_t">Esperando paciente…</p>
    <p class="hk-tarjeta-sub" data-i="espera_s">Pida al paciente que toque "Autorizar médico" en su teléfono, cerca de este computador. No se necesita internet.</p>
  </div>
</div>
<div class="hk-capa" id="solicitud" hidden>
  <div class="hk-tarjeta">
    <div class="hk-tarjeta-icono"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
    <p class="hk-tarjeta-titulo"><span id="solNombre"></span> <span data-i="sol_t">quiere compartir su ficha</span></p>
    <p class="hk-tarjeta-sub" data-i="sol_s">Verifique que el teléfono del paciente muestre este mismo código:</p>
    <p class="hk-codigo" id="solCodigo"></p>
    <div class="hk-fila"><button class="hk-boton hk-sec" onclick="responder(false)" data-i="rechazar">Rechazar</button>
    <button class="hk-boton" onclick="responder(true)" data-i="aceptar">Aceptar</button></div>
  </div>
</div>
'''
extra_css = '''
.hk-codigo{font-size:42px;font-weight:700;letter-spacing:12px;text-align:center;margin:4px 0 6px;color:#0f172a;font-family:'DM Mono',ui-monospace,Consolas,monospace}
.hk-fila{display:flex;gap:10px}.hk-fila>*{flex:1}
'''
extra_js = '''
// ── Lector HypokratIA (programa en el PC) ──
$('ident').hidden=true;
let estadoPrevio='';
async function responder(si){await fetch(si?'/api/aceptar':'/api/rechazar',{method:'POST'})}
async function terminarConsulta(){await fetch('/api/terminar',{method:'POST'})}
function reiniciar(){yo=null;ficha={};fichaOriginal={};fichaTrad={};verOriginal=false;$('avisoTrad').hidden=true;$('esExt').checked=false;$('campoRut').hidden=false;$('campoExt').hidden=true;guardado=false;$('btnGuardar').disabled=false;$('guardada').hidden=true;cerrarCajon();limpiar();
 for(const id of ['pNombre','pRut','pProf'])$(id).textContent='';for(const id of ['pEdad','pSexo','pPrev'])$(id).textContent='—';
 $('avatar').textContent='P';$('nom').value='';$('rut').value=''}
function mostrarEstado(j){window._ultimoEstado=j;
 $('espera').hidden=j.estado!=='espera';
 $('solicitud').hidden=j.estado!=='solicitud';
 if(j.estado==='solicitud'){$('solNombre').textContent=j.paciente||'Un paciente';$('solCodigo').textContent=j.codigo||''}
 if(j.estado==='aceptada'||j.estado==='activa'){if(!yo)$('ident').hidden=false}else $('ident').hidden=true;
 if(j.estado==='espera')reiniciar()}
async function sondeo(){try{const r=await fetch('/api/estado');const j=await r.json();
 if(j.estado!==estadoPrevio){estadoPrevio=j.estado;mostrarEstado(j)}}catch(e){}setTimeout(sondeo,1000)}
(function(){const h=document.querySelector('.da-main-header');const b=document.createElement('button');
 b.className='da-btn-cancel';b.dataset.i='terminar';b.textContent=t('terminar');b.style.marginLeft='auto';b.onclick=terminarConsulta;h.appendChild(b)})();
aplicarIdioma();
sondeo();
'''
pc = base.replace('</style>', extra_css + '</style>', 1).replace('<script>', espera + '<script>', 1)
pc = pc.replace('</script></body>', extra_js + '</script></body>')
pc = pc.replace('<title>HypokratIA · Atención Clínica</title>', '<title>Lector HypokratIA · Atención Clínica</title>')
open(os.path.join(RAIZ, "herramientas/lector_pc/atencion.html"), "w", encoding="utf-8").write(pc)
print("ok:", len(dart), len(pc))

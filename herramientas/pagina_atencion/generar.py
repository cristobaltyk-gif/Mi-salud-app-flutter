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
 $('avatar').textContent='P';$('nom').value='';$('rut').value='';$('resumenAnt').innerHTML=''}
function mostrarEstado(j){window._ultimoEstado=j;
 $('espera').hidden=j.estado!=='espera';
 $('solicitud').hidden=j.estado!=='solicitud';
 if(j.estado==='solicitud'){$('solNombre').textContent=j.paciente||'Un paciente';$('solCodigo').textContent=j.codigo||''}
 if(j.estado==='aceptada'||j.estado==='activa'){if(!yo)$('ident').hidden=false}else $('ident').hidden=true;
 if(j.estado==='espera'){reiniciar();if(dictando)alternarDictado()}}
async function sondeo(){try{const r=await fetch('/api/estado');const j=await r.json();
 if(j.estado!==estadoPrevio){estadoPrevio=j.estado;mostrarEstado(j)}
 if((j.permiso||null)!==permiso){permiso=j.permiso||null;herramientasIA()}}catch(e){}setTimeout(sondeo,1000)}

// ── Dictar y Ordenar con Claude: solo con página segura (https o el PC
//    mismo), internet en el PC y el permiso de la consulta que trajo el
//    teléfono del paciente ("transcribir" / "ordenar"). Si no, apagados. ──
const API_MISALUD='https://portal-api.hipokratia.health';
let permiso=null,dictando=false,reconocedor=null,ordenando=false;
Object.assign(I18N.es,{detener_ordenar:'Detener y ordenar',reordenar:'✨ Ordenar de nuevo',sin_texto:'Escriba o dicte la atención primero.',dictar:'Dictar',detener:'Detener dictado',ordenar:'Ordenar con Claude',ordenando:'Ordenando…',ia_sin_red:'Dictar y ordenar necesitan internet en este computador',ia_sin_permiso:'Dictar y ordenar se activan cuando el teléfono del paciente tiene internet',ia_sin_https:'Este lector aún no tiene dirección segura: el dictado se activa sola cuando la tenga',err_ordenar:'No se pudo ordenar. Intenta de nuevo.',err_micro:'No hay acceso al micrófono. Revisa el permiso del navegador.'});
Object.assign(I18N.en,{detener_ordenar:'Stop and organize',reordenar:'✨ Organize again',sin_texto:'Type or dictate the encounter first.',dictar:'Dictate',detener:'Stop dictation',ordenar:'Organize with Claude',ordenando:'Organizing…',ia_sin_red:'Dictation and organizing need internet on this computer',ia_sin_permiso:'Dictation and organizing turn on when the patient’s phone has internet',ia_sin_https:'This reader has no secure address yet: dictation turns on by itself once it does',err_ordenar:'Could not organize. Try again.',err_micro:'No microphone access. Check the browser permission.'});
Object.assign(I18N.de,{detener_ordenar:'Stoppen und ordnen',reordenar:'✨ Erneut ordnen',sin_texto:'Bitte zuerst die Behandlung schreiben oder diktieren.',dictar:'Diktieren',detener:'Diktat beenden',ordenar:'Mit Claude ordnen',ordenando:'Wird geordnet…',ia_sin_red:'Diktat und Ordnen brauchen Internet auf diesem Computer',ia_sin_permiso:'Diktat und Ordnen werden aktiv, wenn das Telefon des Patienten Internet hat',ia_sin_https:'Dieses Lesegerät hat noch keine sichere Adresse: das Diktat wird automatisch aktiv, sobald es eine hat',err_ordenar:'Ordnen nicht möglich. Bitte erneut versuchen.',err_micro:'Kein Mikrofonzugriff. Prüfen Sie die Browserberechtigung.'});
Object.assign(I18N.fr,{detener_ordenar:'Arrêter et organiser',reordenar:'✨ Réorganiser',sin_texto:'Écrivez ou dictez d’abord la consultation.',dictar:'Dicter',detener:'Arrêter la dictée',ordenar:'Organiser avec Claude',ordenando:'Organisation…',ia_sin_red:'La dictée et l’organisation nécessitent internet sur cet ordinateur',ia_sin_permiso:'La dictée et l’organisation s’activent quand le téléphone du patient a internet',ia_sin_https:'Ce lecteur n’a pas encore d’adresse sécurisée : la dictée s’activera d’elle-même',err_ordenar:'Impossible d’organiser. Réessayez.',err_micro:'Pas d’accès au micro. Vérifiez l’autorisation du navigateur.'});
function usosPermiso(){try{const c=permiso.split('.')[0].replace(/-/g,'+').replace(/_/g,'/');return JSON.parse(atob(c+'==='.slice((c.length+3)%4))).usos||[]}catch(e){return []}}
function herramientasIA(){const usos=permiso?usosPermiso():[];const SR=window.SpeechRecognition||window.webkitSpeechRecognition;
 const red=navigator.onLine,seguro=window.isSecureContext;
 const pDictar=!!SR&&seguro&&red&&usos.includes('transcribir'),pOrdenar=red&&usos.includes('ordenar');
 $('btnDictar').disabled=(!pDictar&&!dictando)||ordenando;
 $('txtDictar').textContent=ordenando?t('ordenando'):dictando?t(pOrdenar?'detener_ordenar':'detener'):t('dictar');
 $('btnDictar').classList.toggle('da-tool-btn--recording',dictando);$('btnDictar').classList.toggle('da-tool-btn--claude',ordenando);
 $('btnReordenar').hidden=!pOrdenar;$('btnReordenar').disabled=ordenando||dictando||!$('atencion').value.trim();$('btnReordenar').textContent=t('reordenar');
 const aviso=!red?'ia_sin_red':!permiso?'ia_sin_permiso':(!seguro&&usos.includes('transcribir'))?'ia_sin_https':'';
 $('avisoIA').textContent=aviso?t(aviso):'';$('avisoIA').hidden=!aviso}
const IDIOMA_VOZ={es:'es-CL',en:'en-US',de:'de-DE',fr:'fr-FR'};
function alternarDictado(){if(dictando){dictando=false;try{reconocedor&&reconocedor.stop()}catch(e){}herramientasIA();
  // Como en la Ficha: al detener, Claude ordena (si el permiso lo incluye)
  if(navigator.onLine&&usosPermiso().includes('ordenar')&&$('atencion').value.trim())setTimeout(ordenarConClaude,600);return}
 const SR=window.SpeechRecognition||window.webkitSpeechRecognition;if(!SR)return;dictando=true;herramientasIA();escuchar(SR)}
function escuchar(SR){const r=new SR();reconocedor=r;r.lang=IDIOMA_VOZ[LANG]||'es-CL';r.continuous=true;r.interimResults=false;
 r.onresult=e=>{let txt='';for(let i=e.resultIndex;i<e.results.length;i++)if(e.results[i].isFinal)txt+=e.results[i][0].transcript.trim()+' ';
  if(txt){const a=$('atencion');a.value=(a.value?a.value.trimEnd()+' ':'')+txt.trim()}};
 r.onerror=e=>{if(['not-allowed','service-not-allowed','audio-capture'].includes(e.error)){dictando=false;$('msg').className='hk-msg hk-err';$('msg').textContent=t('err_micro');herramientasIA()}};
 r.onend=()=>{if(dictando)setTimeout(()=>{if(dictando)escuchar(SR)},300)};
 try{r.start()}catch(e){}}
async function ordenarConClaude(){const texto=$('atencion').value.trim();if(!permiso||ordenando)return;
 if(!texto){const m=$('msg');m.className='hk-msg err';m.textContent=t('sin_texto');$('atencion').focus();return}
 if(dictando){dictando=false;try{reconocedor&&reconocedor.stop()}catch(e){}}ordenando=true;herramientasIA();const m=$('msg');m.textContent='';
 try{const r=await fetch(API_MISALUD+'/api/lector/ordenar',{method:'POST',headers:{'Content-Type':'application/json','X-Permiso-Consulta':permiso},body:JSON.stringify({text:texto})});
  if(!r.ok)throw new Error();const d=await r.json();
  $('atencion').value=d.atencion||texto;$('diagnostico').value=d.diagnostico||'';$('examenes').value=d.examenes||'';
  $('indicaciones').value=d.indicaciones||'';$('orden_kinesiologia').value=d.ordenKinesica||'';$('indicacion_quirurgica').value=d.indicacionQuirurgica||'';
  if((d.medicamentosEstructurados||[]).length){meds=d.medicamentosEstructurados.map(x=>({medicamento:x.medicamento||'',dosis:x.dosis||'',frecuencia_horas:x.frecuencia_horas??'',duracion_dias:x.duracion_dias??'',cronico:!!x.cronico}));pintarMeds()}
 }catch(e){m.className='hk-msg hk-err';m.textContent=t('err_ordenar')}
 finally{ordenando=false;herramientasIA()}}
(function(){const caja=document.querySelector('.da-tools');const icMic='<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/></svg>';
 const icIA='<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l1.9 4.6L18.5 9l-4.6 1.9L12 15.5l-1.9-4.6L5.5 9l4.6-1.4z"/></svg>';
 caja.insertAdjacentHTML('beforeend','<button class="da-tool-btn" id="btnDictar" onclick="alternarDictado()" disabled><span class="da-tool-icon">'+icMic+'</span><span id="txtDictar"></span></button>'
  +'<button type="button" class="da-link-reordenar" id="btnReordenar" onclick="ordenarConClaude()" disabled hidden></button>'
  +'<p id="avisoIA" class="da-tools-label" style="text-transform:none;letter-spacing:0;font-weight:500;line-height:1.35" hidden></p>');
 addEventListener('online',herramientasIA);addEventListener('offline',herramientasIA);$('atencion').addEventListener('input',herramientasIA);herramientasIA()})();
(function(){const h=document.querySelector('.da-main-header');const b=document.createElement('button');
 b.className='da-btn-cancel';b.dataset.i='terminar';b.textContent=t('terminar');b.style.marginLeft='auto';b.onclick=terminarConsulta;h.appendChild(b)})();
// ── Imprimir y enviar por email (como en la Ficha): con internet y solo si el
//    profesional está registrado en el RNPI. Sin firma registrada: firma a mano.
Object.assign(I18N.es,{imprimir:'Imprimir',imprimir_todo:'Imprimir todo',enviar_email:'Enviar por email',imprimiendo:'Preparando documentos…',enviando:'Enviando…',enviado:'Documentos enviados a',sin_docs:'No hay documentos para emitir.',err_docs:'No se pudieron emitir los documentos:',doc_rnpi:'Imprimir y enviar documentos: solo profesionales registrados en el RNPI.',doc_firma:'Los documentos salen sin firma registrada: fírmelos a mano.'});
Object.assign(I18N.en,{imprimir:'Print',imprimir_todo:'Print all',enviar_email:'Send by email',imprimiendo:'Preparing documents…',enviando:'Sending…',enviado:'Documents sent to',sin_docs:'There are no documents to issue.',err_docs:'Could not issue the documents:',doc_rnpi:'Printing and sending documents: only professionals registered in the Chilean RNPI.',doc_firma:'Documents come out without a registered signature: sign them by hand.'});
Object.assign(I18N.de,{imprimir:'Drucken',imprimir_todo:'Alles drucken',enviar_email:'Per E-Mail senden',imprimiendo:'Dokumente werden vorbereitet…',enviando:'Wird gesendet…',enviado:'Dokumente gesendet an',sin_docs:'Keine Dokumente zum Ausstellen.',err_docs:'Dokumente konnten nicht ausgestellt werden:',doc_rnpi:'Dokumente drucken und senden: nur im chilenischen RNPI registrierte Fachpersonen.',doc_firma:'Die Dokumente haben keine hinterlegte Unterschrift: bitte von Hand unterschreiben.'});
Object.assign(I18N.fr,{imprimir:'Imprimer',imprimir_todo:'Tout imprimer',enviar_email:'Envoyer par e-mail',imprimiendo:'Préparation des documents…',enviando:'Envoi…',enviado:'Documents envoyés à',sin_docs:'Aucun document à émettre.',err_docs:'Impossible d’émettre les documents :',doc_rnpi:'Imprimer et envoyer des documents : seulement les professionnels inscrits au RNPI chilien.',doc_firma:'Les documents sortent sans signature enregistrée : signez-les à la main.'});
let profHabil=null,profRevisando=false,emitiendo=false;
const SECCION_DOC={p_receta:'receta',p_examenes:'examenes',p_indicaciones:'informe',p_kine:'kinesiologia',p_quirurgica:'quirurgica'};
function documentoDe(tipo){const p=(fichaOriginal&&fichaOriginal.paciente)||{};const v=id=>($(id)?$(id).value:'').trim();
 const base={nombre:p.nombre,apellido_paterno:p.apellido_paterno,apellido_materno:p.apellido_materno,fecha_nacimiento:p.fecha_nacimiento,edad:edad(p.fecha_nacimiento),rut:p.rut,diagnostico:v('diagnostico')};
 if(tipo==='receta'){const r=recetaTxt().trim();return r&&{tipo,datos:{...base,medicamentos:[],indicaciones:r}}}
 if(tipo==='informe')return v('atencion')&&{tipo,datos:{...base,indicaciones:v('indicaciones')}};
 if(tipo==='examenes')return v('examenes')&&{tipo,datos:{...base,examenes:v('examenes')}};
 if(tipo==='kinesiologia')return v('orden_kinesiologia')&&{tipo,datos:{...base,lado:'',indicaciones:v('orden_kinesiologia')}};
 if(tipo==='quirurgica')return v('indicacion_quirurgica')&&{tipo,datos:{...base,indicaciones:v('indicacion_quirurgica')}};
 return null}
function docsAtencion(){return ['receta','informe','examenes','kinesiologia','quirurgica'].map(documentoDe).filter(Boolean)}
async function revisarProfesional(){if(profRevisando||profHabil!==null||!yo||!permiso||!navigator.onLine||!usosPermiso().includes('documentos'))return;
 profRevisando=true;try{const r=await fetch(API_MISALUD+'/api/lector/profesional',{method:'POST',headers:{'Content-Type':'application/json','X-Permiso-Consulta':permiso},body:JSON.stringify({rut:yo.rut})});
  if(r.ok){const j=await r.json();profHabil=!!j.habilitado}}catch(e){}profRevisando=false;herramientasDoc()}
function herramientasDoc(){const ok=!!yo&&!!permiso&&navigator.onLine&&profHabil===true;
 document.querySelectorAll('.hk-doc').forEach(b=>{b.hidden=!ok;b.disabled=emitiendo});
 document.querySelectorAll('.hk-doc-txt').forEach(s=>s.textContent=t(s.dataset.k));
 const a=$('avisoDoc');const msg=(yo&&permiso&&navigator.onLine&&profHabil===false)?t('doc_rnpi'):'';a.textContent=msg;a.hidden=!msg}
async function emitir(accion,docs){const m=$('msg');m.className='hk-msg';
 if(!docs.length){m.textContent=t('sin_docs');return}
 emitiendo=true;herramientasDoc();m.textContent=t(accion==='email'?'enviando':'imprimiendo');
 try{const r=await fetch(API_MISALUD+'/api/lector/documentos',{method:'POST',headers:{'Content-Type':'application/json','X-Permiso-Consulta':permiso},
   body:JSON.stringify({accion,rut_profesional:yo.rut,fecha:new Date().toISOString().slice(0,10),documentos:docs})});
  if(!r.ok){let d='';try{d=(await r.json()).detail||''}catch(e){}throw new Error(d||('HTTP '+r.status))}
  if(accion==='email'){const j=await r.json();m.textContent=t('enviado')+' '+(j.email||'')}
  else{const url=URL.createObjectURL(await r.blob());let f=$('marcoPdf');if(f)f.remove();f=document.createElement('iframe');f.id='marcoPdf';f.style.display='none';f.src=url;
   f.onload=()=>{try{f.contentWindow.focus();f.contentWindow.print()}catch(e){window.open(url,'_blank')}};document.body.appendChild(f);m.textContent=''}}
 catch(x){m.className='hk-msg err';m.textContent=t('err_docs')+' '+x.message}
 emitiendo=false;herramientasDoc()}
(function(){const icP='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>';
 const icM='<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16v16H4z"/><polyline points="22 6 12 13 2 6"/></svg>';
 for(const [k,tipo] of Object.entries(SECCION_DOC)){const tit=document.querySelector('.da-panel-title[data-i="'+k+'"]');if(!tit)continue;
  tit.parentElement.insertAdjacentHTML('beforeend','<button class="da-print-btn hk-doc" hidden onclick="emitir(\\'imprimir\\',[documentoDe(\\''+tipo+'\\')].filter(Boolean))">'+icP+'<span class="hk-doc-txt" data-k="imprimir"></span></button>')}
 document.querySelector('.da-tools').insertAdjacentHTML('beforeend','<p id="avisoDoc" class="da-tools-label" style="text-transform:none;letter-spacing:0;font-weight:500;line-height:1.35" hidden></p>');
 addEventListener('online',herramientasDoc);addEventListener('offline',herramientasDoc);
 setInterval(()=>{if(!yo&&profHabil!==null){profHabil=null;herramientasDoc()}revisarProfesional();herramientasDoc()},2000)})();
// Después de guardar (como la Ficha): el correo al paciente sale solo y
// aparece "Imprimir todo" + un botón por documento.
Object.assign(I18N.es,{doc_receta:'Receta',doc_informe:'Informe de atención',doc_examenes:'Orden de exámenes',doc_kinesiologia:'Orden kinésica',doc_quirurgica:'Indicación quirúrgica',imprimir_entregar:'Imprime los documentos para entregarlos al paciente.'});
Object.assign(I18N.en,{doc_receta:'Prescription',doc_informe:'Encounter report',doc_examenes:'Test order',doc_kinesiologia:'Physiotherapy order',doc_quirurgica:'Surgical indication',imprimir_entregar:'Print the documents to hand them to the patient.'});
Object.assign(I18N.de,{doc_receta:'Rezept',doc_informe:'Behandlungsbericht',doc_examenes:'Untersuchungsauftrag',doc_kinesiologia:'Physiotherapie-Verordnung',doc_quirurgica:'OP-Indikation',imprimir_entregar:'Drucken Sie die Dokumente für den Patienten aus.'});
Object.assign(I18N.fr,{doc_receta:'Ordonnance',doc_informe:'Compte rendu',doc_examenes:'Demande d’examens',doc_kinesiologia:'Prescription de kinésithérapie',doc_quirurgica:'Indication chirurgicale',imprimir_entregar:'Imprimez les documents à remettre au patient.'});
const _guardar=guardar;guardar=async function(){await _guardar();if(!guardado)return;const caja=$('guardadaDocs');caja.innerHTML='';
 const docs=docsAtencion();if(!docs.length||!yo||!permiso||!navigator.onLine||profHabil!==true)return;
 const b='style="width:100%;margin:6px 0;padding:11px 14px;border-radius:10px;font-weight:700;cursor:pointer;';
 let h='<p class="hk-tarjeta-sub">'+esc(t('imprimir_entregar'))+' '+esc(t('doc_firma'))+'</p><button class="hk-doc" '+b+'border:none;background:#1B3B8C;color:#fff" onclick="emitir(\\'imprimir\\',docsAtencion())">🖨️ '+esc(t('imprimir_todo'))+' ('+docs.length+')</button>';
 for(const d of docs)h+='<button class="hk-doc" '+b+'border:1px solid #e2e8f0;background:#f8fafc;color:#0f172a;text-align:left" onclick="emitir(\\'imprimir\\',[documentoDe(\\''+d.tipo+'\\')].filter(Boolean))">🖨️ '+esc(t('doc_'+d.tipo))+'</button>';
 caja.innerHTML=h;herramientasDoc();emitir('email',docs)};
const _alCambiarIdioma=alCambiarIdioma;alCambiarIdioma=function(){_alCambiarIdioma();herramientasIA();herramientasDoc()};
aplicarIdioma();
sondeo();
'''
pc = base.replace('</style>', extra_css + '</style>', 1).replace('<script>', espera + '<script>', 1)
pc = pc.replace('</script></body>', extra_js + '</script></body>')
pc = pc.replace('<title>HypokratIA · Atención Clínica</title>', '<title>Lector HypokratIA · Atención Clínica</title>')
open(os.path.join(RAIZ, "herramientas/lector_pc/atencion.html"), "w", encoding="utf-8").write(pc)
print("ok:", len(dart), len(pc))

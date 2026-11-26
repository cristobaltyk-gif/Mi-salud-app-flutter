const k=new URLSearchParams(location.search).get('k');
let yo=null,ficha={},meds=[];
const $=id=>document.getElementById(id);
function esc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
async function post(ruta,datos){const r=await fetch(ruta+'?k='+encodeURIComponent(k),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(datos)});
 const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(td(j.detail||'Error'));return j}
function edad(f){if(!f)return '—';const [a,m,d]=String(f).slice(0,10).split('-').map(Number);const h=new Date();
 return (h.getFullYear()-a-((h.getMonth()+1<m||(h.getMonth()+1===m&&h.getDate()<d))?1:0))+' '+t('anios')}
Object.assign(I18N.es,{editar_ant:'Editar antecedentes',modificar:'Modificar',modificada:'Atención modificada',cie_sin:'Sin código',cie_agregar:'+ Agregar',cie_otro:'+ Otro',cie_ph:'Busca por código (M16) o palabras (coxartrosis)…',cie_buscando:'Buscando…',cie_nada:'Sin resultados',ant_nuevo:'Agregar antecedente',ant_desc:'Descripción',ant_fecha:'Fecha de inicio (opcional)',ant_agregar:'Agregar',ant_archivar:'Archivar',ant_deshacer:'Deshacer',ant_pend:'Se guarda con la atención',ant_nuevo_tag:'Nuevo',ant_falta:'Escriba la descripción'});
Object.assign(I18N.en,{editar_ant:'Edit background',modificar:'Modify',modificada:'Encounter modified',cie_sin:'No code',cie_agregar:'+ Add',cie_otro:'+ Another',cie_ph:'Search by code (M16) or words (coxarthrosis)…',cie_buscando:'Searching…',cie_nada:'No results',ant_nuevo:'Add background item',ant_desc:'Description',ant_fecha:'Start date (optional)',ant_agregar:'Add',ant_archivar:'Archive',ant_deshacer:'Undo',ant_pend:'Saved with the encounter',ant_nuevo_tag:'New',ant_falta:'Enter the description'});
Object.assign(I18N.de,{editar_ant:'Vorgeschichte bearbeiten',modificar:'Ändern',modificada:'Behandlung geändert',cie_sin:'Kein Code',cie_agregar:'+ Hinzufügen',cie_otro:'+ Weiterer',cie_ph:'Suche nach Code (M16) oder Wörtern…',cie_buscando:'Suche…',cie_nada:'Keine Ergebnisse',ant_nuevo:'Eintrag hinzufügen',ant_desc:'Beschreibung',ant_fecha:'Beginn (optional)',ant_agregar:'Hinzufügen',ant_archivar:'Archivieren',ant_deshacer:'Rückgängig',ant_pend:'Wird mit der Behandlung gespeichert',ant_nuevo_tag:'Neu',ant_falta:'Bitte Beschreibung eingeben'});
Object.assign(I18N.fr,{editar_ant:'Modifier les antécédents',modificar:'Modifier',modificada:'Consultation modifiée',cie_sin:'Aucun code',cie_agregar:'+ Ajouter',cie_otro:'+ Autre',cie_ph:'Rechercher par code (M16) ou mots…',cie_buscando:'Recherche…',cie_nada:'Aucun résultat',ant_nuevo:'Ajouter un antécédent',ant_desc:'Description',ant_fecha:'Date de début (optionnelle)',ant_agregar:'Ajouter',ant_archivar:'Archiver',ant_deshacer:'Annuler',ant_pend:'Enregistré avec la consultation',ant_nuevo_tag:'Nouveau',ant_falta:'Saisissez la description'});
// ── CIE-10 del diagnóstico (igual que la Ficha). Buscar necesita internet:
//    el lector define buscarCie10(); sin él solo se ven/quitan los códigos.
let cie10=[],cieAbierto=false,cieRes=[],cieBuscando=false,cieTimer=null;
window.buscarCie10=window.buscarCie10||null;
function pintarCie10(){const caja=$('cie10');if(!caja)return;const puede=typeof window.puedeCie10==='function'&&window.puedeCie10();
 let h='<div class="cie10-etiquetas"><span class="cie10-titulo">CIE-10</span>'+cie10.map((c,i)=>'<span class="cie10-etiqueta" title="'+esc(c.descripcion)+'"><strong>'+esc(c.codigo)+'</strong> '+esc(c.descripcion)+'<button type="button" onclick="quitarCie10('+i+')">✕</button></span>').join('');
 if(!cie10.length&&!cieAbierto)h+='<span class="cie10-vacio">'+t('cie_sin')+'</span>';
 if(!cieAbierto&&puede&&cie10.length<5)h+='<button type="button" class="cie10-agregar" onclick="abrirCie10()">'+t(cie10.length?'cie_otro':'cie_agregar')+'</button>';
 h+='</div>';
 if(cieAbierto){h+='<div class="cie10-buscador"><input id="cieQ" placeholder="'+esc(t('cie_ph'))+'" oninput="tecleaCie10(this.value)" onkeydown="if(event.key===\'Escape\')cerrarCie10();if(event.key===\'Enter\'&&cieRes[0]){event.preventDefault();agregarCie10(0)}"><button type="button" class="cie10-cerrar" onclick="cerrarCie10()">'+t('cancelar')+'</button><ul class="cie10-resultados" id="cieLista"></ul></div>'}
 caja.innerHTML=h;if(cieAbierto){const q=$('cieQ');q.value=window._cieQ||'';q.focus();pintarResCie10()}}
function pintarResCie10(){const l=$('cieLista');if(!l)return;const q=(window._cieQ||'').trim();
 l.innerHTML=(cieBuscando&&!cieRes.length?'<li class="cie10-info">'+t('cie_buscando')+'</li>':'')+(!cieBuscando&&!cieRes.length&&q.length>=2?'<li class="cie10-info">'+t('cie_nada')+'</li>':'')+
  cieRes.map((r,i)=>'<li><button type="button" onclick="agregarCie10('+i+')"><strong>'+esc(r.codigo)+'</strong> '+esc(r.descripcion)+'</button></li>').join('');l.hidden=!l.innerHTML}
function abrirCie10(){cieAbierto=true;window._cieQ='';cieRes=[];pintarCie10()}
function cerrarCie10(){cieAbierto=false;window._cieQ='';cieRes=[];pintarCie10()}
function quitarCie10(i){cie10.splice(i,1);pintarCie10()}
function agregarCie10(i){const r=cieRes[i];if(r&&!cie10.some(c=>c.codigo===r.codigo)&&cie10.length<5)cie10.push({codigo:r.codigo,descripcion:r.descripcion});cerrarCie10()}
function tecleaCie10(v){window._cieQ=v;clearTimeout(cieTimer);if(v.trim().length<2||!window.buscarCie10){cieRes=[];pintarResCie10();return}
 cieTimer=setTimeout(async()=>{cieBuscando=true;pintarResCie10();try{cieRes=await window.buscarCie10(v.trim())}catch(e){cieRes=[]}cieBuscando=false;pintarResCie10()},250)}
// ── Editar antecedentes (igual que la Ficha: agregar y archivar). Los cambios
//    viajan con la atención y entran a la ficha con la misma verificación.
let antCambios={agregar:[],archivar:[]};
function agregarAnt(){const d=$('antDesc').value.trim();if(!d){$('antErr').textContent=t('ant_falta');return}
 antCambios.agregar.push({categoria:$('antCat').value,descripcion:d,fecha_inicio:$('antFecha').value||null});verAntecedentes()}
function quitarAntNuevo(i){antCambios.agregar.splice(i,1);verAntecedentes()}
function archivarAnt(id){const k=antCambios.archivar.indexOf(id);if(k<0)antCambios.archivar.push(id);else antCambios.archivar.splice(k,1);verAntecedentes()}
function cambiosAntTexto(){return antCambios.agregar.length||antCambios.archivar.length?JSON.stringify(antCambios):''}
// Nombre como en la Ficha: "Cristóbal Huerta", no en mayúsculas
function nombrePropio(s){return String(s||'').toLowerCase().replace(/(^|[\s-])(\p{L})/gu,(m,a,b)=>a+b.toUpperCase())}
function reloj(){const h=new Date();$('pFecha').textContent=h.getFullYear()+'-'+String(h.getMonth()+1).padStart(2,'0')+'-'+String(h.getDate()).padStart(2,'0');$('pHora').textContent=h.toTimeString().slice(0,5)}
let fichaOriginal={},fichaTrad={},verOriginal=false;
function idProfesional(){
 if($('esExt').checked){const reg=$('regExt').value.trim().replace(/\s+/g,'');const pais=$('paisExt').value.trim().toUpperCase();
  return (reg.length>=3&&/^[A-Z]{2}$/.test(pais))?'EXT-'+pais+'-'+reg:''}
 return $('rut').value.trim()}
function pintarPaciente(){const p=ficha.paciente||{};
 const nombre=[p.nombre,p.apellido_paterno,p.apellido_materno].filter(Boolean).join(' ');
 $('pNombre').textContent=nombre;$('pRut').textContent=p.rut||'';$('avatar').textContent=(nombre||'P').charAt(0).toUpperCase();
 $('pEdad').textContent=edad(p.fecha_nacimiento);$('pSexo').textContent=p.sexo||'—';$('pPrev').textContent=p.prevision||'—';pintarResumen();pintarCie10()}
// Resumen de antecedentes siempre visible, igual que en la Ficha (alergias, medicamentos habituales, enfermedades crónicas)
Object.assign(I18N.es,{res_t:'Antecedentes clínicos',r_alergia:'Alergias',r_medicamento_habitual:'Medicamentos habituales',r_enfermedad_cronica:'Enfermedades crónicas',v_alergia:'SIN ALERGIAS CONOCIDAS',v_medicamento_habitual:'Sin medicamentos registrados',v_enfermedad_cronica:'Sin enfermedades crónicas registradas'});
Object.assign(I18N.en,{res_t:'Clinical background',r_alergia:'Allergies',r_medicamento_habitual:'Regular medications',r_enfermedad_cronica:'Chronic conditions',v_alergia:'NO KNOWN ALLERGIES',v_medicamento_habitual:'No medications recorded',v_enfermedad_cronica:'No chronic conditions recorded'});
Object.assign(I18N.de,{res_t:'Klinische Vorgeschichte',r_alergia:'Allergien',r_medicamento_habitual:'Dauermedikation',r_enfermedad_cronica:'Chronische Erkrankungen',v_alergia:'KEINE BEKANNTEN ALLERGIEN',v_medicamento_habitual:'Keine Medikamente erfasst',v_enfermedad_cronica:'Keine chronischen Erkrankungen erfasst'});
Object.assign(I18N.fr,{res_t:'Antécédents cliniques',r_alergia:'Allergies',r_medicamento_habitual:'Traitements habituels',r_enfermedad_cronica:'Maladies chroniques',v_alergia:'AUCUNE ALLERGIE CONNUE',v_medicamento_habitual:'Aucun médicament enregistré',v_enfermedad_cronica:'Aucune maladie chronique enregistrée'});
const BLOQUES_RES=[['alergia','⚠️','#991b1b','#fef2f2','#fecaca','#fee2e2'],['medicamento_habitual','💊','#1e40af','#eff6ff','#bfdbfe','#dbeafe'],['enfermedad_cronica','🩺','#065f46','#f0fdf4','#86efac','#dcfce7']];
function pintarResumen(){const caja=$('resumenAnt');if(!caja)return;if(!ficha.paciente){caja.innerHTML='';return}const a=ficha.antecedentes||{};
 let h='<div style="margin-bottom:16px"><p style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:#64748b;margin:0 0 8px">'+esc(t('res_t'))+'</p><div style="display:flex;flex-direction:column;gap:8px">';
 for(const [k,emo,col,bg,bor,tag] of BLOQUES_RES){const it=(a[k]||[]).filter(x=>x&&x.descripcion);const vac=!it.length;
  h+='<div style="border-radius:10px;border:1.5px solid '+bor+';background:'+bg+';padding:10px 14px"><div style="display:flex;align-items:center;gap:6px;margin-bottom:'+(vac?0:8)+'px"><span style="font-size:14px">'+emo+'</span><span style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.1em;color:'+col+'">'+esc(t('r_'+k))+'</span></div>';
  h+=vac?'<p style="margin:0;font-size:12px;font-weight:700;color:'+(k==='alergia'?'#991b1b':'#94a3b8')+';font-style:'+(k==='alergia'?'normal':'italic')+'">'+esc(t('v_'+k))+'</p>'
   :'<div style="display:flex;flex-wrap:wrap;gap:5px">'+it.map(x=>'<span style="font-size:12px;font-weight:600;padding:3px 10px;border-radius:20px;background:'+tag+';color:'+col+';border:1px solid '+bor+'">'+esc(x.descripcion)+'</span>').join('')+'</div>';
  h+='</div>'}
 caja.innerHTML=h+'</div></div>'}
async function entrar(){$('e1').textContent='';const id=idProfesional();yo={nombre:$('nom').value.trim(),rut:id};
 if(yo.nombre.length<3||!id){$('e1').textContent=t('err_ident');return}
 try{const j=await post('/api/identificar',yo);fichaOriginal=j.ficha||{};ficha=fichaOriginal;fichaTrad={};verOriginal=false;
  pintarPaciente();$('pProf').textContent=nombrePropio(yo.nombre);reloj();setInterval(reloj,30000);$('ident').hidden=true;
  if(LANG!=='es')traducirFicha()}catch(x){$('e1').textContent=x.message}}
// El teléfono del paciente traduce la ficha, sin internet
async function traducirFicha(){if(!yo)return;
 if(LANG==='es'){ficha=fichaOriginal;$('avisoTrad').hidden=true;pintarPaciente();return}
 if(fichaTrad[LANG]){ficha=verOriginal?fichaOriginal:fichaTrad[LANG];mostrarAviso();pintarPaciente();return}
 $('avisoTrad').hidden=false;$('avisoTxt').textContent=t('traduciendo');$('btnOriginal').hidden=true;
 // El idioma se fija al pedir: si el médico cambia de idioma mientras traduce,
 // la respuesta anterior se guarda con SU idioma y no pisa la pantalla actual.
 const lang=LANG;
 try{const j=await post('/api/idioma',{idioma:lang});const f=j.ficha||{};
  if(f.idioma&&f.idioma!==lang)throw new Error('idioma distinto');
  fichaTrad[lang]=f;if(LANG!==lang)return;verOriginal=false;ficha=f;mostrarAviso();pintarPaciente()}
 catch(x){if(LANG!==lang)return;$('avisoTxt').textContent=t('err_traducir')+' '+x.message;ficha=fichaOriginal;pintarPaciente()}}
function mostrarAviso(){$('avisoTrad').hidden=false;$('avisoTxt').textContent=verOriginal?'':t((fichaTrad[LANG]||{}).traduccion_fuente==='telefono'?'traducida':'traducida_ia');
 $('btnOriginal').hidden=false;$('btnOriginal').textContent=verOriginal?t('ver_traduccion'):t('ver_original')}
function alternarOriginal(){verOriginal=!verOriginal;ficha=verOriginal?fichaOriginal:(fichaTrad[LANG]||fichaOriginal);mostrarAviso();pintarPaciente();
 if(!$('cajon').hidden)cerrarCajon()}
function alCambiarIdioma(){pintarMeds();if(yo)traducirFicha();if(typeof estadoPrevio!=='undefined'&&typeof mostrarEstado==='function'&&window._ultimoEstado)mostrarEstado(window._ultimoEstado)}
const CAMPOS_EV=[['atencion','c_motivo'],['diagnostico','p_diagnostico'],['receta','p_receta'],['examenes','p_examenes'],['indicaciones','p_indicaciones'],['orden_kinesiologia','p_kine'],['indicacion_quirurgica','p_quirurgica']];
const CATEGORIAS={enfermedad_cronica:['Enfermedades crónicas','🩺'],cirugia:['Cirugías','🔬'],alergia:['Alergias','⚠️'],medicamento_habitual:['Medicamentos habituales','💊'],antecedente_familiar:['Antecedentes familiares','👨‍👩‍👧'],otro:['Otros antecedentes','📋']};
const flechaIzq='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>';
const flechaDer='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>';
function valorEv(e,k){if(k==='diagnostico')return e.diagnostico||(e.contenido||{}).diagnostico||'';return (e.contenido||{})[k]||e[k]||''}
function cerrarCajon(){$('cajon').hidden=true;$('velo').hidden=true}
function abrirCajon(){$('cajon').hidden=false;$('velo').hidden=false}
function listaHistorial(){const ev=ficha.eventos||[];
 $('cajonTitulo').innerHTML='<p class="hk-t1">'+t('historial')+'</p><p class="hk-t2">'+ev.length+' '+t('h_atenciones')+'</p>';
 if(!ev.length){$('cajonCuerpo').innerHTML='<div class="hk-vacio">'+t('h_vacio')+'</div>';return}
 $('cajonCuerpo').innerHTML=ev.map((e,i)=>'<div class="hk-fila-ev" onclick="detalleHistorial('+i+')"><div style="flex:1;min-width:0">'+
  '<div style="display:flex;align-items:center;gap:8px"><span class="hk-chip">'+esc(e.fecha)+'</span><span class="hk-t2">'+esc(e.hora||'')+'</span></div>'+
  '<p class="hk-dx">'+esc(valorEv(e,'diagnostico')||t('sin_dx'))+'</p>'+(e.medico?'<p class="hk-prof">'+esc(e.medico)+'</p>':'')+
  '</div><span style="color:#cbd5e1">'+flechaDer+'</span></div>').join('')}
function detalleHistorial(i){const ev=ficha.eventos||[];const e=ev[i];
 $('cajonTitulo').innerHTML='<button class="hk-volver" onclick="listaHistorial()">'+flechaIzq.replace('14','16').replace('14','16')+t('historial')+'</button>';
 let h='<div class="hk-nav"><button '+(i===0?'disabled':'')+' onclick="detalleHistorial('+(i-1)+')">'+flechaIzq+t('anterior')+'</button><span class="hk-t2">'+(i+1)+' / '+ev.length+'</span><button '+(i===ev.length-1?'disabled':'')+' onclick="detalleHistorial('+(i+1)+')">'+t('siguiente')+flechaDer+'</button></div>';
 h+='<div style="padding:16px 20px 12px;border-bottom:1px solid #f1f5f9"><div style="display:flex;gap:8px;margin-bottom:6px"><span class="hk-chip hk-osc">'+esc(e.fecha)+'</span>'+(e.hora?'<span class="hk-chip">'+esc(e.hora)+'</span>':'')+'</div>'+(e.medico?'<p class="hk-prof" style="font-size:12px">'+esc(e.medico)+(e.especialidad?' · '+esc(e.especialidad):'')+'</p>':'')+'</div><div style="padding:0 20px">';
 for(const [k,l] of CAMPOS_EV){const v=String(valorEv(e,k)||'').trim();if(v)h+='<div class="hk-campo"><p class="hk-campo-l">'+t(l)+'</p><p class="hk-campo-v">'+esc(v)+'</p></div>'}
 $('cajonCuerpo').innerHTML=h+'</div>'}
function verAntecedentes(){const a=ficha.antecedentes||{};const ks=Object.keys(a).filter(x=>(a[x]||[]).length);
 const n=ks.reduce((t,x)=>t+a[x].length,0);
 $('cajonTitulo').innerHTML='<p class="hk-t1">'+t('editar_ant')+'</p><p class="hk-t2">'+n+' '+t('a_registrados')+'</p>';
 const bt='style="border:1px solid #e2e8f0;background:#fff;border-radius:8px;padding:3px 9px;font-size:11px;cursor:pointer;margin-left:8px;flex-shrink:0"';
 let h=!ks.length&&!antCambios.agregar.length?'<div class="hk-vacio">'+t('a_vacio')+'</div>':'';
 h+=ks.map(x=>{const em=(CATEGORIAS[x]||['','📋'])[1];const l=CATEGORIAS[x]?t('cat_'+x):x.replace(/_/g,' ');
  return '<div class="hk-cat"><p class="hk-cat-l">'+em+' '+esc(l)+'</p>'+a[x].map(i=>{const arch=i.id!=null&&antCambios.archivar.includes(i.id);
   return '<div class="hk-item" style="display:flex;align-items:center;justify-content:space-between'+(arch?';text-decoration:line-through;opacity:.5':'')+'"><span>'+esc(i.descripcion)+'</span>'+(i.id!=null?'<button '+bt+' onclick="archivarAnt('+Number(i.id)+')">'+t(arch?'ant_deshacer':'ant_archivar')+'</button>':'')+'</div>'}).join('')+'</div>'}).join('');
 if(antCambios.agregar.length)h+='<div class="hk-cat"><p class="hk-cat-l">✚ '+t('ant_nuevo_tag')+' · '+t('ant_pend')+'</p>'+antCambios.agregar.map((x,i)=>'<div class="hk-item" style="display:flex;align-items:center;justify-content:space-between"><span>'+(CATEGORIAS[x.categoria]||['','📋'])[1]+' '+esc(x.descripcion)+'</span><button '+bt+' onclick="quitarAntNuevo('+i+')">✕</button></div>').join('')+'</div>';
 const st='width:100%;box-sizing:border-box;border:1px solid #e2e8f0;border-radius:8px;padding:8px 10px;font:inherit;font-size:13px;margin-bottom:8px';
 h+='<div style="padding:14px 20px 20px;border-top:1px solid #f1f5f9"><p class="hk-cat-l">'+t('ant_nuevo')+'</p>'+
  '<select id="antCat" style="'+st+'">'+Object.keys(CATEGORIAS).map(k=>'<option value="'+k+'">'+CATEGORIAS[k][1]+' '+esc(t('cat_'+k))+'</option>').join('')+'</select>'+
  '<input id="antDesc" style="'+st+'" placeholder="'+esc(t('ant_desc'))+'"><input id="antFecha" type="date" style="'+st+'" title="'+esc(t('ant_fecha'))+'">'+
  '<p id="antErr" style="color:#b91c1c;font-size:12px;margin:0 0 6px"></p><button class="hk-boton" onclick="agregarAnt()">'+t('ant_agregar')+'</button></div>';
 $('cajonCuerpo').innerHTML=h}
function abrir(que){if(que==='historial')listaHistorial();else verAntecedentes();abrirCajon()}
function sanear(){return meds.filter(m=>m.medicamento&&m.medicamento.trim()).map(m=>({medicamento:m.medicamento.trim(),dosis:(m.dosis||'').trim(),
 frecuencia_horas:m.frecuencia_horas===''||m.frecuencia_horas==null?null:parseInt(m.frecuencia_horas,10),
 duracion_dias:m.cronico||m.duracion_dias===''||m.duracion_dias==null?null:parseInt(m.duracion_dias,10),cronico:!!m.cronico}))}
function linea(m){const r=[];if(m.dosis)r.push(m.dosis);if(m.frecuencia_horas!=null)r.push(t('cada')+' '+m.frecuencia_horas+' '+t('horas'));
 if(m.duracion_dias!=null)r.push(t('por')+' '+m.duracion_dias+' '+t('dias'));if(m.cronico)r.push(t('cronico'));const t=r.join(' ');return t?m.medicamento+' — '+t:m.medicamento}
function recetaTxt(){return sanear().map(linea).join('\n')}
function pintarMeds(){$('medVacio').hidden=meds.length>0;let h='';
 meds.forEach((m,i)=>{h+='<div class="da-medicamento-row">'+
  '<input class="da-med-input da-med-input--nombre" placeholder="'+esc(t('ph_med'))+'" value="'+esc(m.medicamento)+'" oninput="setMed('+i+',\'medicamento\',this.value)">'+
  '<input class="da-med-input da-med-input--dosis" placeholder="'+esc(t('ph_dosis'))+'" value="'+esc(m.dosis)+'" oninput="setMed('+i+',\'dosis\',this.value)">'+
  '<div class="da-med-frecuencia"><span>'+t('cada')+'</span><input type="number" min="0" class="da-med-input da-med-input--numero" placeholder="8" value="'+esc(m.frecuencia_horas)+'" oninput="setMed('+i+',\'frecuencia_horas\',this.value)"><span>'+t('horas')+'</span></div>'+
  (m.cronico?'':'<div class="da-med-duracion"><span>'+t('por')+'</span><input type="number" min="0" class="da-med-input da-med-input--numero" placeholder="7" value="'+esc(m.duracion_dias)+'" oninput="setMed('+i+',\'duracion_dias\',this.value)"><span>'+t('dias')+'</span></div>')+
  '<label class="da-med-duracion" style="cursor:pointer;user-select:none"><input type="checkbox" style="width:15px;height:15px;min-height:0;margin:0;padding:0;flex:0 0 auto" '+(m.cronico?'checked':'')+' onchange="setCronico('+i+',this.checked)"><span>'+t('cronico')+'</span></label>'+
  '<button type="button" class="da-med-eliminar" onclick="quitarMed('+i+')" title="'+esc(t('eliminar_med'))+'"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button></div>'});
 $('meds').innerHTML=h;vista()}
function vista(){const t=recetaTxt();$('preview').hidden=!t;$('previewTxt').textContent=t}
function setMed(i,c,v){meds[i][c]=v;vista()}
function setCronico(i,v){meds[i].cronico=v;if(v)meds[i].duracion_dias='';pintarMeds()}
function agregarMed(){meds.push({medicamento:'',dosis:'',frecuencia_horas:'',duracion_dias:'',cronico:false});pintarMeds()}
function quitarMed(i){meds.splice(i,1);pintarMeds()}
const CAMPOS=['atencion','diagnostico','indicaciones','examenes','orden_kinesiologia','indicacion_quirurgica'];
function limpiar(){for(const c of CAMPOS)$(c).value='';meds=[];pintarMeds();cie10=[];cieAbierto=false;pintarCie10();if(!guardado){antCambios={agregar:[],archivar:[]}}$('msg').textContent=''}
let guardado=false;
let modificando=false;
async function guardar(){if(guardado&&!modificando)return;const m=$('msg');m.className='hk-msg';m.textContent='';
 const contenido={};for(const c of CAMPOS)contenido[c]=$(c).value;contenido.receta=recetaTxt();contenido.medicamentos=JSON.stringify(sanear());
 contenido.diagnostico_cie10=JSON.stringify(cie10);contenido.antecedentes=cambiosAntTexto();
 const b=modificando?$('btnModificar'):$('btnGuardar');
 try{b.disabled=true;await post('/api/nota',{...yo,contenido,reemplazar:modificando});const era=modificando;guardado=true;modificando=false;
  $('guardadaTxt').textContent=era?t('modificada'):t('guardada_s');$('guardada').hidden=false;b.disabled=false}
 catch(x){b.disabled=false;m.className='hk-msg err';m.textContent=x.message}}
// Modificar (como la Ficha): la atención sigue en el teléfono hasta Terminar
function modificarAtencion(){modificando=true;$('guardada').hidden=true;$('btnGuardar').hidden=true;$('btnModificar').hidden=false}
function terminarDesdeGuardada(){if(typeof terminarConsulta==='function')terminarConsulta();else{$('guardadaTxt').textContent=t('terminada');$('guardadaBtn').hidden=true}}
document.querySelectorAll('textarea').forEach(t=>t.addEventListener('input',()=>{t.style.height='auto';t.style.height=t.scrollHeight+'px'}));
pintarMeds();pintarCie10();
aplicarIdioma();

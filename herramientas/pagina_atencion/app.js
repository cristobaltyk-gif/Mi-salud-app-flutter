const k=new URLSearchParams(location.search).get('k');
let yo=null,ficha={},meds=[];
const $=id=>document.getElementById(id);
function esc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
async function post(ruta,datos){const r=await fetch(ruta+'?k='+encodeURIComponent(k),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(datos)});
 const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.detail||'Error');return j}
function edad(f){if(!f)return '—';const [a,m,d]=String(f).slice(0,10).split('-').map(Number);const h=new Date();
 return (h.getFullYear()-a-((h.getMonth()+1<m||(h.getMonth()+1===m&&h.getDate()<d))?1:0))+' años'}
function reloj(){const h=new Date();$('pFecha').textContent=h.toLocaleDateString('es-CL');$('pHora').textContent=h.toTimeString().slice(0,5)}
async function entrar(){$('e1').textContent='';yo={nombre:$('nom').value.trim(),rut:$('rut').value.trim()};
 try{const j=await post('/api/identificar',yo);ficha=j.ficha||{};const p=ficha.paciente||{};
  const nombre=[p.nombre,p.apellido_paterno,p.apellido_materno].filter(Boolean).join(' ');
  $('pNombre').textContent=nombre;$('pRut').textContent=p.rut||'';$('avatar').textContent=(nombre||'P').charAt(0).toUpperCase();
  $('pEdad').textContent=edad(p.fecha_nacimiento);$('pSexo').textContent=p.sexo||'—';$('pPrev').textContent=p.prevision||'—';
  $('pProf').textContent=yo.nombre;reloj();setInterval(reloj,30000);$('ident').hidden=true}catch(x){$('e1').textContent=x.message}}
const CAMPOS_EV=[['atencion','Motivo de consulta'],['diagnostico','Diagnóstico'],['receta','Receta'],['examenes','Exámenes'],['indicaciones','Indicaciones'],['orden_kinesiologia','Orden kinésica'],['indicacion_quirurgica','Indicación quirúrgica']];
const CATEGORIAS={enfermedad_cronica:['Enfermedades crónicas','🩺'],cirugia:['Cirugías','🔬'],alergia:['Alergias','⚠️'],medicamento_habitual:['Medicamentos habituales','💊'],antecedente_familiar:['Antecedentes familiares','👨‍👩‍👧'],otro:['Otros antecedentes','📋']};
const flechaIzq='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>';
const flechaDer='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>';
function valorEv(e,k){if(k==='diagnostico')return e.diagnostico||(e.contenido||{}).diagnostico||'';return (e.contenido||{})[k]||e[k]||''}
function cerrarCajon(){$('cajon').hidden=true;$('velo').hidden=true}
function abrirCajon(){$('cajon').hidden=false;$('velo').hidden=false}
function listaHistorial(){const ev=ficha.eventos||[];
 $('cajonTitulo').innerHTML='<p class="hk-t1">Historial clínico</p><p class="hk-t2">'+ev.length+' atenciones</p>';
 if(!ev.length){$('cajonCuerpo').innerHTML='<div class="hk-vacio">Sin atenciones previas registradas</div>';return}
 $('cajonCuerpo').innerHTML=ev.map((e,i)=>'<div class="hk-fila-ev" onclick="detalleHistorial('+i+')"><div style="flex:1;min-width:0">'+
  '<div style="display:flex;align-items:center;gap:8px"><span class="hk-chip">'+esc(e.fecha)+'</span><span class="hk-t2">'+esc(e.hora||'')+'</span></div>'+
  '<p class="hk-dx">'+esc(valorEv(e,'diagnostico')||'Sin diagnóstico')+'</p>'+(e.medico?'<p class="hk-prof">'+esc(e.medico)+'</p>':'')+
  '</div><span style="color:#cbd5e1">'+flechaDer+'</span></div>').join('')}
function detalleHistorial(i){const ev=ficha.eventos||[];const e=ev[i];
 $('cajonTitulo').innerHTML='<button class="hk-volver" onclick="listaHistorial()">'+flechaIzq.replace('14','16').replace('14','16')+'Historial</button>';
 let h='<div class="hk-nav"><button '+(i===0?'disabled':'')+' onclick="detalleHistorial('+(i-1)+')">'+flechaIzq+'Anterior</button><span class="hk-t2">'+(i+1)+' / '+ev.length+'</span><button '+(i===ev.length-1?'disabled':'')+' onclick="detalleHistorial('+(i+1)+')">Siguiente'+flechaDer+'</button></div>';
 h+='<div style="padding:16px 20px 12px;border-bottom:1px solid #f1f5f9"><div style="display:flex;gap:8px;margin-bottom:6px"><span class="hk-chip hk-osc">'+esc(e.fecha)+'</span>'+(e.hora?'<span class="hk-chip">'+esc(e.hora)+'</span>':'')+'</div>'+(e.medico?'<p class="hk-prof" style="font-size:12px">'+esc(e.medico)+(e.especialidad?' · '+esc(e.especialidad):'')+'</p>':'')+'</div><div style="padding:0 20px">';
 for(const [k,l] of CAMPOS_EV){const v=String(valorEv(e,k)||'').trim();if(v)h+='<div class="hk-campo"><p class="hk-campo-l">'+l+'</p><p class="hk-campo-v">'+esc(v)+'</p></div>'}
 $('cajonCuerpo').innerHTML=h+'</div>'}
function verAntecedentes(){const a=ficha.antecedentes||{};const ks=Object.keys(a).filter(x=>(a[x]||[]).length);
 const n=ks.reduce((t,x)=>t+a[x].length,0);
 $('cajonTitulo').innerHTML='<p class="hk-t1">Antecedentes</p><p class="hk-t2">'+n+' registrados</p>';
 if(!ks.length){$('cajonCuerpo').innerHTML='<div class="hk-vacio">Sin antecedentes registrados</div>';return}
 $('cajonCuerpo').innerHTML=ks.map(x=>{const [l,em]=CATEGORIAS[x]||[x.replace(/_/g,' '),'📋'];
  return '<div class="hk-cat"><p class="hk-cat-l">'+em+' '+esc(l)+'</p>'+a[x].map(i=>'<div class="hk-item">'+esc(i.descripcion)+'</div>').join('')+'</div>'}).join('')}
function abrir(que){if(que==='historial')listaHistorial();else verAntecedentes();abrirCajon()}
function sanear(){return meds.filter(m=>m.medicamento&&m.medicamento.trim()).map(m=>({medicamento:m.medicamento.trim(),dosis:(m.dosis||'').trim(),
 frecuencia_horas:m.frecuencia_horas===''||m.frecuencia_horas==null?null:parseInt(m.frecuencia_horas,10),
 duracion_dias:m.cronico||m.duracion_dias===''||m.duracion_dias==null?null:parseInt(m.duracion_dias,10),cronico:!!m.cronico}))}
function linea(m){const r=[];if(m.dosis)r.push(m.dosis);if(m.frecuencia_horas!=null)r.push('cada '+m.frecuencia_horas+' horas');
 if(m.duracion_dias!=null)r.push('por '+m.duracion_dias+' días');if(m.cronico)r.push('uso crónico');const t=r.join(' ');return t?m.medicamento+' — '+t:m.medicamento}
function recetaTxt(){return sanear().map(linea).join('\n')}
function pintarMeds(){$('medVacio').hidden=meds.length>0;let h='';
 meds.forEach((m,i)=>{h+='<div class="da-medicamento-row">'+
  '<input class="da-med-input da-med-input--nombre" placeholder="Medicamento (ej. Ibuprofeno 400mg)" value="'+esc(m.medicamento)+'" oninput="setMed('+i+',\'medicamento\',this.value)">'+
  '<input class="da-med-input da-med-input--dosis" placeholder="Dosis (ej. 1 comprimido)" value="'+esc(m.dosis)+'" oninput="setMed('+i+',\'dosis\',this.value)">'+
  '<div class="da-med-frecuencia"><span>cada</span><input type="number" min="0" class="da-med-input da-med-input--numero" placeholder="8" value="'+esc(m.frecuencia_horas)+'" oninput="setMed('+i+',\'frecuencia_horas\',this.value)"><span>horas</span></div>'+
  (m.cronico?'':'<div class="da-med-duracion"><span>por</span><input type="number" min="0" class="da-med-input da-med-input--numero" placeholder="7" value="'+esc(m.duracion_dias)+'" oninput="setMed('+i+',\'duracion_dias\',this.value)"><span>días</span></div>')+
  '<label class="da-med-duracion" style="cursor:pointer;user-select:none"><input type="checkbox" style="width:15px;height:15px;min-height:0;margin:0;padding:0;flex:0 0 auto" '+(m.cronico?'checked':'')+' onchange="setCronico('+i+',this.checked)"><span>uso crónico</span></label>'+
  '<button type="button" class="da-med-eliminar" onclick="quitarMed('+i+')" title="Eliminar medicamento"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button></div>'});
 $('meds').innerHTML=h;vista()}
function vista(){const t=recetaTxt();$('preview').hidden=!t;$('previewTxt').textContent=t}
function setMed(i,c,v){meds[i][c]=v;vista()}
function setCronico(i,v){meds[i].cronico=v;if(v)meds[i].duracion_dias='';pintarMeds()}
function agregarMed(){meds.push({medicamento:'',dosis:'',frecuencia_horas:'',duracion_dias:'',cronico:false});pintarMeds()}
function quitarMed(i){meds.splice(i,1);pintarMeds()}
const CAMPOS=['atencion','diagnostico','indicaciones','examenes','orden_kinesiologia','indicacion_quirurgica'];
function limpiar(){for(const c of CAMPOS)$(c).value='';meds=[];pintarMeds();$('msg').textContent=''}
let guardado=false;
async function guardar(){if(guardado)return;const m=$('msg');m.className='hk-msg';m.textContent='';
 const contenido={};for(const c of CAMPOS)contenido[c]=$(c).value;contenido.receta=recetaTxt();contenido.medicamentos=JSON.stringify(sanear());
 try{$('btnGuardar').disabled=true;await post('/api/nota',{...yo,contenido});guardado=true;$('guardada').hidden=false}
 catch(x){$('btnGuardar').disabled=false;m.className='hk-msg err';m.textContent=x.message}}
function terminarDesdeGuardada(){if(typeof terminarConsulta==='function')terminarConsulta();else{$('guardadaTxt').textContent='Consulta terminada. Puede cerrar esta ventana.';$('guardadaBtn').hidden=true}}
document.querySelectorAll('textarea').forEach(t=>t.addEventListener('input',()=>{t.style.height='auto';t.style.height=t.scrollHeight+'px'}));
pintarMeds();

/// lib/services/consulta_sin_conexion_service.dart — v1.0
///
/// CONSULTA SIN CONEXIÓN: el teléfono del paciente hace de servidor.
///
/// 1. Crea su propia red Wi-Fi local (MainActivity.kt, solo Android). Si no
///    puede, usa la red Wi-Fi a la que esté conectado (sin internet sirve igual).
/// 2. Abre un pequeño servidor web dentro de la app, solo en esa red.
/// 3. La pantalla muestra dos QR: el de la red (el equipo se conecta solo) y el
///    de la página, con una llave de un solo uso en la dirección.
/// 4. El profesional se identifica (nombre y RUT), ve la ficha en su
///    navegador y escribe su nota. La nota vuelve al teléfono, se sella y
///    queda pendiente (notas_offline_service.dart). Al equipo no se descarga
///    ningún archivo.
/// 5. El teléfono manda el tiempo: al vencer el plazo o al tocar "Terminar",
///    el servidor y la red se apagan y la página deja de funcionar.
///    Solo el primer equipo que entra con la llave puede usarla.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notas_offline_service.dart';

class ConsultaException implements Exception {
  final String mensaje;
  ConsultaException(this.mensaje);
  @override
  String toString() => mensaje;
}

class AccesoProfesional {
  final String nombre;
  final String rut;
  final DateTime cuando;
  AccesoProfesional(this.nombre, this.rut, this.cuando);
}

class SesionConsulta {
  final String? ssid;      // null = se usa la red Wi-Fi actual
  final String? clave;
  final String url;
  final DateTime vence;
  SesionConsulta({required this.ssid, required this.clave, required this.url, required this.vence});

  /// Formato estándar de QR de Wi-Fi: el teléfono/tablet o Windows 11 se conecta solo.
  String? get qrWifi {
    if (ssid == null || ssid!.isEmpty) return null;
    String esc(String s) => s.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');
    return 'WIFI:T:WPA;S:${esc(ssid!)};P:${esc(clave ?? '')};;';
  }
}

class ConsultaSinConexionService {
  static const MethodChannel _canal = MethodChannel('misalud/red_local');
  static HttpServer? _servidor;
  static Timer? _reloj;
  static String? _llave;
  static String? _ipDelEquipo;
  static Map<String, dynamic>? _ficha;
  static String? _rutPaciente;
  static DateTime? _aceptadaAt;
  static final List<AccesoProfesional> accesos = [];
  static final StreamController<void> _cambios = StreamController<void>.broadcast();

  /// Avisa a la pantalla cuando entra un profesional, llega una nota o termina.
  static Stream<void> get cambios => _cambios.stream;
  static bool get activa => _servidor != null;
  static int notasRecibidas = 0;

  /// Android 13+ pide "dispositivos cercanos"; antes, ubicación. Si la
  /// persona no lo da, se intenta igual con la red Wi-Fi actual.
  static Future<void> _permisos() async {
    if (!Platform.isAndroid) {
      throw ConsultaException('La consulta sin conexión por red local está disponible solo en Android.');
    }
    try {
      if (!(await Permission.nearbyWifiDevices.request()).isGranted) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {}
  }

  static Future<Map<String, String?>?> _crearRed() async {
    try {
      final r = await _canal.invokeMapMethod<String, dynamic>('iniciar');
      if (r == null || (r['ssid'] as String?)?.isNotEmpty != true) return null;
      return {'ssid': r['ssid'] as String?, 'clave': r['clave'] as String?};
    } on PlatformException {
      return null; // se intenta con la red Wi-Fi actual
    }
  }

  /// IP del teléfono en la red local: primero la red propia (ap/swlan), luego el Wi-Fi.
  static Future<String?> _ipLocal({required bool redPropia}) async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
    String? mejor;
    var mejorPuntaje = 99;
    for (final i in interfaces) {
      final n = i.name.toLowerCase();
      if (n.contains('rmnet') || n.contains('ccmni') || n.contains('tun')) continue; // datos móviles / VPN
      for (final a in i.addresses) {
        if (a.isLoopback || a.isLinkLocal) continue;
        var p = 5;
        if (n.contains('wlan') || n.contains('ap') || n.contains('swlan')) p = 2;
        // La red propia del teléfono: el teléfono es la puerta (termina en .1)
        if (redPropia && (n.contains('ap') || n.contains('swlan') || a.address.endsWith('.1'))) p = 0;
        if (p < mejorPuntaje) { mejorPuntaje = p; mejor = a.address; }
      }
    }
    return mejor;
  }

  static String _nuevaLlave() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Comienza la consulta. `ficha` es la ficha ya descifrada del teléfono.
  static Future<SesionConsulta> iniciar({
    required String rutPaciente,
    required Map<String, dynamic> ficha,
    required DateTime aceptadaAt,
    Duration duracion = const Duration(minutes: 30),
  }) async {
    await terminar();
    await _permisos();

    final red = await _crearRed();
    final ip = await _ipLocal(redPropia: red != null);
    if (ip == null) {
      await _canal.invokeMethod('detener').catchError((_) {});
      throw ConsultaException('No se pudo crear la red local. Activa el Wi-Fi del teléfono e intenta de nuevo, '
          'o conéctalo a la misma red Wi-Fi que el equipo del profesional.');
    }

    _servidor = await HttpServer.bind(InternetAddress.anyIPv4, 8080).catchError(
        (_) => HttpServer.bind(InternetAddress.anyIPv4, 0));
    _llave = _nuevaLlave();
    _ipDelEquipo = null;
    _ficha = ficha;
    _rutPaciente = rutPaciente;
    _aceptadaAt = aceptadaAt;
    accesos.clear();
    notasRecibidas = 0;
    _servidor!.listen(_atender, onError: (_) {});

    final vence = DateTime.now().add(duracion);
    _reloj = Timer(duracion, terminar);
    _cambios.add(null);
    return SesionConsulta(
      ssid: red?['ssid'],
      clave: red?['clave'],
      url: 'http://$ip:${_servidor!.port}/?k=$_llave',
      vence: vence,
    );
  }

  /// Apaga el servidor y la red. La página del profesional deja de funcionar.
  static Future<void> terminar() async {
    _reloj?.cancel();
    _reloj = null;
    final s = _servidor;
    _servidor = null;
    _llave = null;
    _ficha = null;
    await s?.close(force: true);
    try {
      await _canal.invokeMethod('detener');
    } catch (_) {}
    if (s != null) _cambios.add(null);
  }

  // ── Servidor ──────────────────────────────────────────────────────────────
  static Future<void> _atender(HttpRequest req) async {
    final res = req.response;
    res.headers.set('Cache-Control', 'no-store');
    res.headers.set('X-Frame-Options', 'DENY');
    res.headers.set('Referrer-Policy', 'no-referrer');
    try {
      final ip = req.connectionInfo?.remoteAddress.address;
      final llaveOk = _llave != null && req.uri.queryParameters['k'] == _llave;
      if (!llaveOk) return _responder(res, 403, {'detail': 'Acceso vencido o inválido'});
      // Solo el primer equipo que entra con la llave
      _ipDelEquipo ??= ip;
      if (_ipDelEquipo != ip) return _responder(res, 403, {'detail': 'Esta consulta ya está abierta en otro equipo'});

      final ruta = req.uri.path;
      if (req.method == 'GET' && ruta == '/') {
        res.headers.contentType = ContentType.html;
        res.write(_pagina);
        await res.close();
        return;
      }
      if (req.method == 'POST' && ruta == '/api/identificar') {
        final b = await _cuerpo(req);
        final nombre = (b['nombre'] as String? ?? '').trim();
        final rut = (b['rut'] as String? ?? '').trim();
        if (nombre.length < 3 || !_rutValido(rut)) {
          return _responder(res, 400, {'detail': 'Ingresa tu nombre completo y un RUT válido'});
        }
        accesos.add(AccesoProfesional(nombre, rut, DateTime.now()));
        _cambios.add(null);
        return _responder(res, 200, {'ficha': _ficha});
      }
      if (req.method == 'POST' && ruta == '/api/nota') {
        final b = await _cuerpo(req);
        final nombre = (b['nombre'] as String? ?? '').trim();
        final rut = (b['rut'] as String? ?? '').trim();
        if (nombre.length < 3 || !_rutValido(rut)) {
          return _responder(res, 400, {'detail': 'Falta tu nombre o RUT'});
        }
        final contenido = <String, String>{
          for (final c in NotasOfflineService.campos) c: ((b['contenido'] as Map?)?[c] as String? ?? ''),
        };
        if (contenido.values.every((v) => v.trim().isEmpty)) {
          return _responder(res, 400, {'detail': 'La nota está vacía'});
        }
        await NotasOfflineService.guardar(
          rutPaciente: _rutPaciente!,
          medicoRut: rut,
          medicoNombre: nombre,
          aceptadaAt: _aceptadaAt!,
          contenido: contenido,
        );
        notasRecibidas++;
        _cambios.add(null);
        return _responder(res, 200, {'ok': true});
      }
      return _responder(res, 404, {'detail': 'No encontrado'});
    } catch (_) {
      return _responder(res, 400, {'detail': 'Solicitud inválida'});
    }
  }

  static Future<Map<String, dynamic>> _cuerpo(HttpRequest req) async {
    final bytes = await req.fold<List<int>>([], (a, b) => a..addAll(b));
    if (bytes.length > 200000) throw const FormatException('muy grande');
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  static Future<void> _responder(HttpResponse res, int codigo, Map<String, dynamic> datos) {
    res.statusCode = codigo;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(datos));
    return res.close();
  }

  /// Dígito verificador del RUT chileno (módulo 11).
  static bool _rutValido(String rut) {
    final limpio = rut.replaceAll(RegExp(r'[.\s]'), '').toUpperCase();
    final m = RegExp(r'^(\d{6,8})-?([\dK])$').firstMatch(limpio);
    if (m == null) return false;
    var suma = 0, mult = 2;
    for (final d in m[1]!.split('').reversed) {
      suma += int.parse(d) * mult;
      mult = mult == 7 ? 2 : mult + 1;
    }
    final r = 11 - (suma % 11);
    final dv = r == 11 ? '0' : r == 10 ? 'K' : '$r';
    return dv == m[2];
  }

  // ── Página que ve el profesional (todo en un archivo, sin internet) ───────
  static const String _pagina = r'''<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>HypokratIA · Consulta sin conexión</title>
<style>
body{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#f5f3ff;color:#1f1b2e}
header{background:#4c1d95;color:#fff;padding:14px 20px;font-weight:700}
main{max-width:900px;margin:0 auto;padding:20px}
.card{background:#fff;border-radius:12px;padding:16px 18px;margin:12px 0;box-shadow:0 1px 3px #0001}
h2{font-size:17px;margin:0 0 8px;color:#4c1d95} h3{font-size:15px;margin:0 0 4px}
label{display:block;font-size:13px;margin:10px 0 4px;color:#555}
input,textarea{width:100%;box-sizing:border-box;padding:9px;border:1px solid #ccc;border-radius:8px;font:inherit}
textarea{min-height:70px}
button{background:#4c1d95;color:#fff;border:0;border-radius:8px;padding:11px 18px;font-weight:600;margin-top:12px;cursor:pointer}
.muted{color:#777;font-size:13px} .err{color:#b91c1c;font-size:14px} .ok{color:#15803d;font-size:14px}
.ev{border-top:1px solid #eee;padding:10px 0} pre{white-space:pre-wrap;font:inherit;margin:4px 0}
</style></head><body>
<header>HypokratIA · Consulta sin conexión</header>
<main>
<div id="id" class="card"><h2>Identifíquese</h2>
<p class="muted">El paciente le comparte su ficha bajo su responsabilidad. Su nombre y RUT quedan registrados.
Al volver la conexión se verifican en el Registro Nacional de Prestadores Individuales (RNPI).</p>
<label>Nombre completo</label><input id="nom" autocomplete="name">
<label>RUT (ej. 12345678-9)</label><input id="rut">
<button onclick="entrar()">Ver ficha</button><p id="e1" class="err"></p></div>
<div id="ficha" hidden></div>
<div id="nota" class="card" hidden><h2>Nota de la consulta</h2>
<p class="muted">Queda sellada en el teléfono del paciente y no se puede modificar después.</p>
<label>Motivo / atención</label><textarea id="atencion"></textarea>
<label>Diagnóstico</label><textarea id="diagnostico"></textarea>
<label>Indicaciones</label><textarea id="indicaciones"></textarea>
<label>Receta</label><textarea id="receta"></textarea>
<label>Exámenes</label><textarea id="examenes"></textarea>
<button onclick="guardar()">Guardar nota</button><p id="e2"></p></div>
</main>
<script>
const k=new URLSearchParams(location.search).get('k');
let yo=null;
function esc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
async function post(ruta,datos){const r=await fetch(ruta+'?k='+encodeURIComponent(k),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(datos)});
 const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.detail||'Error');return j}
async function entrar(){const e=document.getElementById('e1');e.textContent='';
 yo={nombre:document.getElementById('nom').value.trim(),rut:document.getElementById('rut').value.trim()};
 try{const j=await post('/api/identificar',yo);mostrar(j.ficha||{});document.getElementById('id').hidden=true;
 document.getElementById('nota').hidden=false}catch(x){e.textContent=x.message}}
function mostrar(f){const p=f.paciente||{};let h='<div class="card"><h2>'+esc([p.nombre,p.apellido_paterno,p.apellido_materno].filter(Boolean).join(' '))+'</h2>';
 h+='<div class="muted">RUT '+esc(p.rut||'')+(p.fecha_nacimiento?' · Nac. '+esc(p.fecha_nacimiento):'')+(p.sexo?' · '+esc(p.sexo):'')+(p.prevision?' · '+esc(p.prevision):'')+'</div>';
 h+='<div class="muted">Copia generada: '+esc(f.generado_at||'')+'</div></div>';
 const a=f.antecedentes||{};const ks=Object.keys(a).filter(c=>(a[c]||[]).length);
 if(ks.length){h+='<div class="card"><h2>Antecedentes</h2>';for(const c of ks){h+='<h3>'+esc(c.replace(/_/g,' '))+'</h3><ul>';
  for(const x of a[c])h+='<li>'+esc(x.descripcion)+'</li>';h+='</ul>'}h+='</div>'}
 if((f.recordatorios||[]).length){h+='<div class="card"><h2>Medicamentos</h2><ul>';for(const r of f.recordatorios)h+='<li>'+esc(r.medicamento||r.titulo||r.nombre||'')+' '+esc(r.dosis||'')+'</li>';h+='</ul></div>'}
 const ev=f.eventos||[];const ind=f.eventos_con_indicaciones||[];
 h+='<div class="card"><h2>Atenciones ('+(ev.length||ind.length)+')</h2>';
 for(const e of ev){const c=e.contenido||{};h+='<div class="ev"><h3>'+esc(e.fecha)+' · '+esc(e.especialidad||e.tipo||'')+' · '+esc(e.medico||'')+'</h3>';
  for(const [t,v] of [['Diagnóstico',e.diagnostico],['Atención',c.atencion],['Indicaciones',c.indicaciones],['Receta',c.receta],['Exámenes',c.examenes],['Evolución',c.evolucion]])
   if(v)h+='<div><b>'+t+':</b><pre>'+esc(v)+'</pre></div>';h+='</div>'}
 for(const e of ind)h+='<div class="ev"><h3>'+esc(e.fecha)+'</h3><pre>'+esc(e.indicaciones)+'</pre></div>';
 h+='</div>';const d=document.getElementById('ficha');d.innerHTML=h;d.hidden=false}
async function guardar(){const m=document.getElementById('e2');m.className='';m.textContent='';
 const contenido={};for(const c of ['atencion','diagnostico','indicaciones','receta','examenes'])contenido[c]=document.getElementById(c).value;
 try{await post('/api/nota',{...yo,contenido});m.className='ok';m.textContent='Nota guardada y sellada en el teléfono del paciente.';
 for(const c in contenido)document.getElementById(c).value=''}catch(x){m.className='err';m.textContent=x.message}}
</script></body></html>''';
}

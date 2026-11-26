/// lib/services/lector_service.dart — v1.1
///
/// LECTOR HYPOKRATIA: consulta sin internet con el PC del médico.
/// Hoy el lector es un programa en el PC (herramientas/lector_pc/lector.py);
/// mañana será la cajita. El teléfono no cambia.
///
/// 1. esperarConexion(): el teléfono se ANUNCIA por Bluetooth y el PC lo
///    encuentra y se conecta solo (sin emparejar; muchos PC no pueden
///    anunciarse, pero todos pueden buscar). A la vez prueba la red local.
/// 2. SesionLector: intercambio de llaves X25519 → todo cifrado AES-256-GCM.
///    Teléfono y PC muestran el MISMO código de 4 números; el médico acepta.
/// 3. Se envía la ficha (la copia cifrada del teléfono, descifrada aquí).
/// 4. El PC avisa cada acceso (médico que entra) y manda cada nota: el
///    teléfono los registra y sella (notas_offline_service.dart) y responde.
///    Al volver la red se suben: RNPI → ficha / historial; si no → superadmin.
///
/// Mensajes: [4 bytes largo][JSON]. Mismos valores que en lector.py.
library;

import 'dart:async';
import '../i18n/idioma.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notas_offline_service.dart';
import 'storage_service.dart';
import 'http_sesion.dart' as red;
import '../config/app_config.dart';
import 'traduccion_service.dart';

const String _servicioBle = '6e8a0001-6b1f-4c39-9d0e-48495046b001';
const String _caractRx = '6e8a0002-6b1f-4c39-9d0e-48495046b001'; // teléfono → PC
const String _caractTx = '6e8a0003-6b1f-4c39-9d0e-48495046b001'; // PC → teléfono
const int _puertoBusqueda = 47800;
const List<int> _sal = [
  104, 105, 112, 111, 107, 114, 97, 116, 105, 97, 45, 108, 101, 99, 116, 111, 114, 45, 49
]; // "hipokratia-lector-1"

class LectorException implements Exception {
  final String mensaje;
  LectorException(this.mensaje);
  @override
  String toString() => mensaje;
}

// ── Canales: Bluetooth o red, ambos como un flujo de bytes ──────────────────
abstract class _Canal {
  Stream<List<int>> get entrada;
  Future<void> enviar(List<int> datos);
  Future<void> cerrar();
}

class _CanalRed implements _Canal {
  final Socket _s;
  _CanalRed(this._s);
  @override
  Stream<List<int>> get entrada => _s;
  @override
  Future<void> enviar(List<int> datos) async {
    _s.add(datos);
    await _s.flush();
  }

  @override
  Future<void> cerrar() async => _s.destroy();
}

/// Bluetooth con el teléfono como PERIFÉRICO: el PC escribe en RX y el
/// teléfono responde por notificaciones en TX.
class _CanalBlePeriferico implements _Canal {
  final String dispositivo; // id del PC conectado
  final StreamController<List<int>> _ctrl;
  int trozo;
  _CanalBlePeriferico(this.dispositivo, this._ctrl, this.trozo);

  @override
  Stream<List<int>> get entrada => _ctrl.stream;

  @override
  Future<void> enviar(List<int> datos) async {
    for (var i = 0; i < datos.length; i += trozo) {
      await BlePeripheral.updateCharacteristic(
        characteristicId: _caractTx,
        value: Uint8List.fromList(datos.sublist(i, min(i + trozo, datos.length))),
        deviceId: dispositivo,
      );
      await Future.delayed(const Duration(milliseconds: 8));
    }
  }

  @override
  Future<void> cerrar() async {
    LectorService._canalBle = null;
    try {
      await BlePeripheral.stopAdvertising();
    } catch (_) {}
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

class LectorService {
  static bool _listo = false;
  static _CanalBlePeriferico? _canalBle;
  static StreamController<List<int>>? _entradaBle;
  static int _mtu = 23;

  /// Si el teléfono no pudo anunciarse por Bluetooth, el motivo (se muestra).
  static String? ultimoErrorBle;

  /// Prepara el Bluetooth del teléfono (una vez).
  static Future<void> _prepararBle() async {
    if (_listo) return;
    await BlePeripheral.initialize();
    BlePeripheral.setMtuChangeCallback((_, mtu) {
      _mtu = mtu;
      _canalBle?.trozo = max(20, min(500, mtu - 3));
    });
    BlePeripheral.setWriteRequestCallback((id, caract, offset, valor) {
      final e = _entradaBle;
      if (caract.toLowerCase() == _caractRx && valor != null && e != null && !e.isClosed) e.add(valor);
      return null;
    });
    BlePeripheral.setConnectionStateChangeCallback((id, conectado) {
      final e = _entradaBle;
      if (!conectado && _canalBle?.dispositivo == id && e != null && !e.isClosed) e.close();
    });
    await BlePeripheral.addService(BleService(
      uuid: _servicioBle,
      primary: true,
      characteristics: [
        BleCharacteristic(
          uuid: _caractRx,
          properties: [CharacteristicProperties.write.index, CharacteristicProperties.writeWithoutResponse.index],
          permissions: [AttributePermissions.writeable.index],
        ),
        BleCharacteristic(
          uuid: _caractTx,
          properties: [CharacteristicProperties.notify.index, CharacteristicProperties.read.index],
          permissions: [AttributePermissions.readable.index],
        ),
      ],
    ));
    _listo = true;
  }

  /// Se anuncia por Bluetooth y, a la vez, busca un lector en la red local.
  /// Devuelve el primer canal que se conecte (o null si nadie llega a tiempo).
  static Future<_Canal?> esperarConexion({Duration limite = const Duration(seconds: 60)}) async {
    final listo = Completer<_Canal?>();
    ultimoErrorBle = null;
    // ── Bluetooth: el PC encuentra al teléfono ──
    try {
      if (Platform.isAndroid) {
        await [Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.bluetoothScan].request();
      }
      await BlePeripheral.askBlePermission();
      await _prepararBle();
      _entradaBle = StreamController<List<int>>();
      BlePeripheral.setCharacteristicSubscriptionChangeCallback((id, caract, suscrito, _) {
        if (suscrito && caract.toLowerCase() == _caractTx && !listo.isCompleted) {
          _canalBle = _CanalBlePeriferico(id, _entradaBle!, max(20, min(500, _mtu - 3)));
          listo.complete(_canalBle);
        }
      });
      // Sin nombre: el identificador de 128 bits ya ocupa casi todo el anuncio
      // (máx. 31 bytes); con nombre Android lo rechaza sin avisar. Además
      // localName le cambiaría el nombre Bluetooth al teléfono.
      final anuncio = Completer<String?>();
      BlePeripheral.setAdvertisingStatusUpdateCallback((ok, error) {
        if (!anuncio.isCompleted) anuncio.complete(ok ? null : (error ?? tr('error desconocido')));
      });
      await BlePeripheral.startAdvertising(services: [_servicioBle]);
      ultimoErrorBle = await anuncio.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (e) {
      ultimoErrorBle = e.toString(); // sin Bluetooth: queda la red local
    }
    // ── Red local (si el teléfono está en la misma red que el PC) ──
    unawaited(_buscarRed().then((s) {
      if (s != null && !listo.isCompleted) listo.complete(_CanalRed(s));
    }).catchError((_) {}));

    final canal = await listo.future.timeout(limite, onTimeout: () => null);
    if (canal is! _CanalBlePeriferico) {
      try {
        await BlePeripheral.stopAdvertising();
      } catch (_) {}
    }
    return canal;
  }

  /// Pregunta por la red local; si un lector responde, se conecta.
  static Future<Socket?> _buscarRed() async {
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.broadcastEnabled = true;
    final encontrado = Completer<Socket?>();
    s.listen((e) async {
      if (e != RawSocketEvent.read || encontrado.isCompleted) return;
      final d = s.receive();
      if (d == null) return;
      final partes = utf8.decode(d.data, allowMalformed: true).trim().split(' ');
      if (partes.length >= 2 && partes[0] == 'HIPOKRATIA_LECTOR' && !encontrado.isCompleted) {
        try {
          final sock = await Socket.connect(d.address, int.tryParse(partes[1]) ?? 47801,
              timeout: const Duration(seconds: 6));
          if (!encontrado.isCompleted) encontrado.complete(sock);
        } catch (_) {}
      }
    });
    final pregunta = utf8.encode('HIPOKRATIA_LECTOR?');
    for (var i = 0; i < 20 && !encontrado.isCompleted; i++) {
      try {
        s.send(pregunta, InternetAddress('255.255.255.255'), _puertoBusqueda);
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
    s.close();
    return encontrado.isCompleted ? encontrado.future : null;
  }
}

// ── La consulta ─────────────────────────────────────────────────────────────
class SesionLector {
  final String rutPaciente;
  final Map<String, dynamic> ficha;
  final DateTime aceptadaAt;

  _Canal? _canal;
  SecretKey? _clave;
  final _buf = BytesBuilder();
  final _hola = Completer<Map<String, dynamic>>();
  final _respuesta = Completer<bool>(); // aceptado / rechazado

  /// 'conectando' | 'codigo' | 'activa' | 'rechazada' | 'terminada'
  String estado = 'conectando';
  String codigo = '';
  String equipo = '';
  final List<ProfesionalLector> profesionales = [];
  int notas = 0;
  final Map<String, String> _accesoPorRut = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();
  Stream<void> get cambios => _cambios.stream;

  SesionLector({required this.rutPaciente, required this.ficha, required this.aceptadaAt});

  String get _nombrePaciente {
    final p = (ficha['paciente'] as Map?) ?? {};
    return [p['nombre'], p['apellido_paterno']].where((x) => (x ?? '').toString().isNotEmpty).join(' ');
  }

  /// Espera a que el PC del médico se conecte, intercambia llaves y deja el
  /// código listo para comparar. false = ningún lector llegó a tiempo.
  Future<bool> conectar({Duration limite = const Duration(seconds: 60)}) async {
    _canal = await LectorService.esperarConexion(limite: limite);
    if (_canal == null) return false;
    _canal!.entrada.listen(_recibirBytes, onDone: _cerrado, onError: (_) => _cerrado());

    final x25519 = X25519();
    final par = await x25519.newKeyPair();
    final pub = (await par.extractPublicKey()).bytes;
    await _enviarPlano({'tipo': 'hola', 'pub': base64Encode(pub), 'nombre': _nombrePaciente});

    final h = await _hola.future.timeout(const Duration(seconds: 15),
        onTimeout: () => throw LectorException(tr('El lector no respondió.')));
    final pubPc = base64Decode(h['pub'] as String);
    equipo = (h['equipo'] as String?) ?? '';
    final secreto = await x25519.sharedSecretKey(
      keyPair: par,
      remotePublicKey: SimplePublicKey(pubPc, type: KeyPairType.x25519),
    );
    Future<List<int>> derivar(String info, int largo) async {
      final k = await Hkdf(hmac: Hmac.sha256(), outputLength: largo).deriveKey(
        secretKey: secreto,
        nonce: _sal,
        info: [...utf8.encode(info), ...pub, ...pubPc],
      );
      return k.extractBytes();
    }

    _clave = SecretKey(await derivar('clave', 32));
    final c = await derivar('codigo', 4);
    final n = ByteData.sublistView(Uint8List.fromList(c)).getUint32(0) % 10000;
    codigo = n.toString().padLeft(4, '0');
    estado = 'codigo';
    _cambios.add(null);

    // Espera a que el médico toque ACEPTAR en su PC
    final aceptado = await _respuesta.future.timeout(const Duration(minutes: 3),
        onTimeout: () => throw LectorException(tr('El médico no aceptó a tiempo.')));
    if (!aceptado) {
      estado = 'rechazada';
      _cambios.add(null);
      await terminar(avisar: false);
      return true;
    }
    await _enviar({'tipo': 'ficha', 'ficha': TraduccionService.sinTraducciones(ficha)});
    estado = 'activa';
    _cambios.add(null);
    unawaited(_enviarPermiso());
    return true;
  }

  // ── Permiso de consulta (dictar / ordenar) y certificado del lector ──
  // Solo si el teléfono tiene internet; si no, la consulta sigue igual sin IA.
  String? _permiso;

  Future<void> _enviarPermiso() async {
    try {
      if (!await red.hayInternet()) return;
      final token = await StorageService.obtenerToken();
      if (token == null || token.isEmpty) return;
      final r = await red.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/lector/permiso'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'rut_paciente': rutPaciente}),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200 || _clave == null) return;
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      _permiso = d['permiso'] as String?;
      await _enviar({'tipo': 'permiso', 'permiso': _permiso, 'usos': d['usos'], 'ahora': d['ahora']});
    } catch (_) {
      // Sin permiso: dictar y ordenar quedan apagados en el lector
    }
  }

  // Datos públicos del RNPI del profesional, para que el paciente vea a quién
  // le está mostrando su ficha (cualquier profesión). Sin red: queda pendiente.
  Future<void> _verificarRnpi(ProfesionalLector p) async {
    try {
      if (!await red.hayInternet()) {
        p.estadoRnpi = 'sin_red';
      } else {
        final token = await StorageService.obtenerToken();
        final r = await red.post(
          Uri.parse('${AppConfig.backendBaseUrl}/api/lector/rnpi'),
          headers: {'Authorization': 'Bearer ${token ?? ''}', 'Content-Type': 'application/json'},
          body: jsonEncode({'rut': p.rut}),
        ).timeout(const Duration(seconds: 25));
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body) as Map<String, dynamic>;
          if (d['encontrado'] == true) {
            p.rnpi = d;
            p.estadoRnpi = 'ok';
          } else {
            p.estadoRnpi = d['consultado'] == true ? 'no' : 'error';
          }
        } else {
          p.estadoRnpi = 'error';
        }
      }
    } catch (_) {
      p.estadoRnpi = 'error';
    }
    if (!_cambios.isClosed) _cambios.add(null);
  }

  // El lector pide renovar su certificado https (lo emite nuestro servidor);
  // el teléfono solo lleva la solicitud y trae la respuesta.
  Future<void> _llevarCertificado(Map<String, dynamic> m) async {
    String? cert;
    String? error;
    try {
      if (_permiso == null) throw Exception('sin permiso');
      final r = await red.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/lector/certificado'),
        headers: {'X-Permiso-Consulta': _permiso!, 'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': m['nombre'], 'csr': m['csr']}),
      ).timeout(const Duration(minutes: 3));
      if (r.statusCode == 200) {
        cert = (jsonDecode(r.body) as Map<String, dynamic>)['certificado'] as String?;
      } else {
        error = 'HTTP ${r.statusCode}';
      }
    } catch (e) {
      error = e.toString();
    }
    if (_clave == null || _canal == null) return;
    try {
      await _enviar({'tipo': 'certificado', if (cert != null) 'certificado': cert, if (error != null) 'error': error});
    } catch (_) {}
  }

  Future<void> terminar({bool avisar = true}) async {
    if (avisar && _clave != null) {
      try {
        await _enviar({'tipo': 'fin'});
      } catch (_) {}
    }
    for (final id in _accesoPorRut.values) {
      try {
        await NotasOfflineService.cerrarAcceso(id);
      } catch (_) {}
    }
    _accesoPorRut.clear();
    try {
      await _canal?.cerrar();
    } catch (_) {}
    _canal = null;
    if (estado != 'rechazada') estado = 'terminada';
    if (!_cambios.isClosed) _cambios.add(null);
  }

  // ── mensajes ──
  void _recibirBytes(List<int> datos) {
    _buf.add(datos);
    var todo = _buf.takeBytes();
    while (todo.length >= 4) {
      final largo = ByteData.sublistView(todo, 0, 4).getUint32(0);
      if (todo.length < 4 + largo) break;
      final msg = utf8.decode(todo.sublist(4, 4 + largo));
      todo = todo.sublist(4 + largo);
      _procesar(jsonDecode(msg) as Map<String, dynamic>);
    }
    _buf.add(todo);
  }

  Future<void> _procesar(Map<String, dynamic> obj) async {
    if (_clave == null) {
      if (obj['tipo'] == 'hola' && !_hola.isCompleted) _hola.complete(obj);
      return;
    }
    final m = await _descifrar(obj);
    switch (m['tipo']) {
      case 'aceptado':
        if (!_respuesta.isCompleted) _respuesta.complete(true);
        break;
      case 'rechazado':
        if (!_respuesta.isCompleted) _respuesta.complete(false);
        break;
      case 'acceso':
        final rut = (m['rut'] as String? ?? '').trim();
        final nombre = (m['nombre'] as String? ?? '').trim();
        if (!_accesoPorRut.containsKey(rut)) {
          _accesoPorRut[rut] = await NotasOfflineService.registrarAcceso(
            rutPaciente: rutPaciente,
            medicoRut: rut,
            medicoNombre: nombre,
            fin: DateTime.now().add(const Duration(hours: 3)),
          );
          final p = ProfesionalLector(nombre: nombre, rut: rut);
          profesionales.add(p);
          _cambios.add(null);
          unawaited(_verificarRnpi(p));
        }
        await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': true});
        break;
      case 'nota':
        if (notas > 0) {
          // Una atención por consulta, igual que en la Ficha
          await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': false, 'detail': 'La atención de esta consulta ya fue guardada'});
          break;
        }
        try {
          final c = (m['contenido'] as Map?) ?? {};
          await NotasOfflineService.guardar(
            rutPaciente: rutPaciente,
            medicoRut: (m['rut'] as String? ?? '').trim(),
            medicoNombre: (m['nombre'] as String? ?? '').trim(),
            aceptadaAt: aceptadaAt,
            contenido: {for (final k in NotasOfflineService.campos) k: (c[k] ?? '').toString()},
          );
          notas++;
          _cambios.add(null);
          await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': true});
        } catch (_) {
          await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': false, 'detail': 'No se pudo guardar la nota'});
        }
        break;
      case 'idioma':
        // El médico eligió otro idioma: la ficha se traduce aquí, sin internet
        try {
          final traducida = await TraduccionService.traducirFicha(ficha, (m['idioma'] ?? '').toString());
          await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': true, 'ficha': traducida});
        } catch (e) {
          await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': false, 'detail': e.toString().replaceFirst('Exception: ', '')});
        }
        break;
      case 'certificado_pedir':
        unawaited(_llevarCertificado(m));
        break;
      case 'fin':
        await terminar(avisar: false);
        break;
    }
  }

  void _cerrado() {
    if (!_respuesta.isCompleted) _respuesta.complete(false);
    if (estado == 'activa' || estado == 'codigo') terminar(avisar: false);
  }

  List<int> _marco(Map<String, dynamic> obj) {
    final d = utf8.encode(jsonEncode(obj));
    final b = ByteData(4)..setUint32(0, d.length);
    return [...b.buffer.asUint8List(), ...d];
  }

  Future<void> _enviarPlano(Map<String, dynamic> obj) => _canal!.enviar(_marco(obj));

  Future<void> _enviar(Map<String, dynamic> obj) async {
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final caja = await AesGcm.with256bits().encrypt(utf8.encode(jsonEncode(obj)), secretKey: _clave!, nonce: nonce);
    await _canal!.enviar(_marco({'e': base64Encode([...nonce, ...caja.cipherText, ...caja.mac.bytes])}));
  }

  Future<Map<String, dynamic>> _descifrar(Map<String, dynamic> obj) async {
    final raw = base64Decode(obj['e'] as String);
    final caja = SecretBox(raw.sublist(12, raw.length - 16),
        nonce: raw.sublist(0, 12), mac: Mac(raw.sublist(raw.length - 16)));
    final claro = await AesGcm.with256bits().decrypt(caja, secretKey: _clave!);
    return jsonDecode(utf8.decode(claro)) as Map<String, dynamic>;
  }
}

/// Profesional identificado en el lector, con sus datos del RNPI.
/// estadoRnpi: 'verificando' | 'ok' | 'no' (no está en RNPI) |
/// 'sin_red' (se verificará al volver internet) | 'error' (RNPI no respondió)
class ProfesionalLector {
  final String nombre;
  final String rut;
  String estadoRnpi = 'verificando';
  Map<String, dynamic>? rnpi;
  ProfesionalLector({required this.nombre, required this.rut});
}

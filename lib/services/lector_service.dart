/// lib/services/lector_service.dart — v1.0
///
/// LECTOR HYPOKRATIA: consulta sin internet con el PC del médico.
/// Hoy el lector es un programa en el PC (herramientas/lector_pc/lector.py);
/// mañana será la cajita. El teléfono no cambia.
///
/// 1. buscar(): Bluetooth y red local (Wi-Fi/cable sin internet) a la vez.
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
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notas_offline_service.dart';

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

class LectorEncontrado {
  final String nombre;
  final String medio; // 'Bluetooth' | 'Red local'
  final BluetoothDevice? dispositivo;
  final InternetAddress? host;
  final int? puerto;
  LectorEncontrado.ble(this.nombre, this.dispositivo)
      : medio = 'Bluetooth', host = null, puerto = null;
  LectorEncontrado.red(this.nombre, this.host, this.puerto)
      : medio = 'Red local', dispositivo = null;
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

class _CanalBle implements _Canal {
  final BluetoothDevice _d;
  final BluetoothCharacteristic _rx;
  final StreamController<List<int>> _ctrl = StreamController<List<int>>();
  StreamSubscription<List<int>>? _sub;
  int _trozo = 180;

  _CanalBle(this._d, this._rx);

  static Future<_CanalBle> abrir(BluetoothDevice d) async {
    await d.connect(timeout: const Duration(seconds: 12), autoConnect: false);
    var mtu = 23;
    if (Platform.isAndroid) {
      try {
        mtu = await d.requestMtu(512);
      } catch (_) {}
    } else {
      mtu = d.mtuNow;
    }
    final servicios = await d.discoverServices();
    final s = servicios.firstWhere(
      (x) => x.uuid.str128.toLowerCase() == _servicioBle,
      orElse: () => throw LectorException('El lector no responde como HypokratIA'),
    );
    BluetoothCharacteristic c(String id) =>
        s.characteristics.firstWhere((x) => x.uuid.str128.toLowerCase() == id);
    final canal = _CanalBle(d, c(_caractRx));
    canal._trozo = max(20, min(500, mtu - 3));
    final tx = c(_caractTx);
    canal._sub = tx.onValueReceived.listen(canal._ctrl.add);
    await tx.setNotifyValue(true);
    return canal;
  }

  @override
  Stream<List<int>> get entrada => _ctrl.stream;

  @override
  Future<void> enviar(List<int> datos) async {
    for (var i = 0; i < datos.length; i += _trozo) {
      await _rx.write(datos.sublist(i, min(i + _trozo, datos.length)), withoutResponse: false);
    }
  }

  @override
  Future<void> cerrar() async {
    await _sub?.cancel();
    await _ctrl.close();
    try {
      await _d.disconnect();
    } catch (_) {}
  }
}

// ── Búsqueda ────────────────────────────────────────────────────────────────
class LectorService {
  /// Busca lectores cerca, por Bluetooth y por red local, durante ~5 segundos.
  static Future<List<LectorEncontrado>> buscar() async {
    final encontrados = <LectorEncontrado>[];
    await Future.wait([
      _buscarBle(encontrados).catchError((_) {}),
      _buscarRed(encontrados).catchError((_) {}),
    ]);
    return encontrados;
  }

  static Future<void> _buscarBle(List<LectorEncontrado> lista) async {
    if (Platform.isAndroid) {
      await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }
    }
    if (!await FlutterBluePlus.isSupported) return;
    final vistos = <String>{};
    final sub = FlutterBluePlus.onScanResults.listen((resultados) {
      for (final r in resultados) {
        final id = r.device.remoteId.str;
        if (vistos.add(id)) {
          final nombre = r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : 'HypokratIA';
          lista.add(LectorEncontrado.ble(nombre, r.device));
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(withServices: [Guid(_servicioBle)], timeout: const Duration(seconds: 5));
      await FlutterBluePlus.isScanning.where((s) => s == false).first;
    } finally {
      await sub.cancel();
    }
  }

  static Future<void> _buscarRed(List<LectorEncontrado> lista) async {
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.broadcastEnabled = true;
    final vistos = <String>{};
    s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s.receive();
      if (d == null) return;
      final partes = utf8.decode(d.data, allowMalformed: true).trim().split(' ');
      if (partes.length >= 2 && partes[0] == 'HIPOKRATIA_LECTOR' && vistos.add(d.address.address)) {
        final nombre = partes.length > 2 ? partes.sublist(2).join(' ') : 'Computador';
        lista.add(LectorEncontrado.red(nombre, d.address, int.tryParse(partes[1]) ?? 47801));
      }
    });
    final pregunta = utf8.encode('HIPOKRATIA_LECTOR?');
    for (var i = 0; i < 3; i++) {
      try {
        s.send(pregunta, InternetAddress('255.255.255.255'), _puertoBusqueda);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    s.close();
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
  final List<String> profesionales = [];
  int notas = 0;
  final Map<String, String> _accesoPorRut = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();
  Stream<void> get cambios => _cambios.stream;

  SesionLector({required this.rutPaciente, required this.ficha, required this.aceptadaAt});

  String get _nombrePaciente {
    final p = (ficha['paciente'] as Map?) ?? {};
    return [p['nombre'], p['apellido_paterno']].where((x) => (x ?? '').toString().isNotEmpty).join(' ');
  }

  /// Conecta, intercambia llaves y deja el código listo para comparar.
  Future<void> conectar(LectorEncontrado lector) async {
    try {
      _canal = lector.dispositivo != null
          ? await _CanalBle.abrir(lector.dispositivo!)
          : _CanalRed(await Socket.connect(lector.host, lector.puerto!, timeout: const Duration(seconds: 6)));
    } catch (e) {
      throw LectorException('No se pudo conectar con el lector (${lector.medio}).');
    }
    _canal!.entrada.listen(_recibirBytes, onDone: _cerrado, onError: (_) => _cerrado());

    final x25519 = X25519();
    final par = await x25519.newKeyPair();
    final pub = (await par.extractPublicKey()).bytes;
    await _enviarPlano({'tipo': 'hola', 'pub': base64Encode(pub), 'nombre': _nombrePaciente});

    final h = await _hola.future.timeout(const Duration(seconds: 15),
        onTimeout: () => throw LectorException('El lector no respondió.'));
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
        onTimeout: () => throw LectorException('El médico no aceptó a tiempo.'));
    if (!aceptado) {
      estado = 'rechazada';
      _cambios.add(null);
      await terminar(avisar: false);
      return;
    }
    await _enviar({'tipo': 'ficha', 'ficha': ficha});
    estado = 'activa';
    _cambios.add(null);
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
          profesionales.add('$nombre ($rut)');
          _cambios.add(null);
        }
        await _enviar({'tipo': 'ok', 'n': m['n'], 'ok': true});
        break;
      case 'nota':
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

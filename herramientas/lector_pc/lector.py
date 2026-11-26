"""
Lector HypokratIA — programa para el PC de la consulta (prototipo v1.0).

Hace en el PC lo que después hará la cajita: recibe la ficha desde el teléfono
del paciente SIN INTERNET y la muestra en el navegador del médico con la misma
pantalla de "Atención Clínica" de la Ficha.

Cómo llega el teléfono (busca las dos a la vez):
  · Bluetooth (BLE): el teléfono se anuncia como "HypokratIA" y el PC lo
    busca y se conecta solo (sin emparejar).
  · Red local (Wi-Fi o cable, sin internet): responde a la búsqueda del
    teléfono y recibe la conexión.

Seguridad:
  · Intercambio de llaves X25519 por cada consulta; todo lo demás va cifrado
    con AES-256-GCM.
  · Teléfono y PC muestran el MISMO código de 4 números; el médico toca
    ACEPTAR solo si coinciden (evita que otro equipo se interponga).
  · La ficha queda solo en la memoria del programa. Nada se escribe en el
    disco. Al terminar, se borra.
  · Las notas y los accesos se envían al teléfono, que los sella y los sube
    a la Ficha cuando vuelve la red (RNPI → ficha; si no → superadmin).
  · La página solo se abre desde este mismo PC (127.0.0.1).

Uso:  python lector.py        (ver LEEME.md)
"""
from __future__ import annotations

import asyncio
import base64
import json
import os
import re
import socket
import struct
import sys
import webbrowser
from typing import Any, Callable, Dict, Optional

from aiohttp import web
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

VERSION = "2.0"
NOMBRE_EQUIPO = os.environ.get("HK_NOMBRE", socket.gethostname())[:40]

# Mismos valores en la app (lib/services/lector_service.dart)
SERVICIO_BLE = "6e8a0001-6b1f-4c39-9d0e-48495046b001"
CARACT_RX = "6e8a0002-6b1f-4c39-9d0e-48495046b001"   # teléfono → PC (escritura)
CARACT_TX = "6e8a0003-6b1f-4c39-9d0e-48495046b001"   # PC → teléfono (notificación)
PUERTO_BUSQUEDA = 47800      # UDP: "HIPOKRATIA_LECTOR?"
PUERTO_DATOS = 47801         # TCP: la consulta
PUERTO_WEB = 47880           # navegador del médico (solo este PC)
SAL = b"hipokratia-lector-1"
MAX_MENSAJE = 8 * 1024 * 1024


def log(*a: Any) -> None:
    print("[lector]", *a, flush=True)


# ══════════════════════════════════════════════════════════════
# Mensajes: [4 bytes largo][JSON]. Sirve igual por Bluetooth o por red.
# ══════════════════════════════════════════════════════════════
class Ensamblador:
    """Junta los pedazos que llegan (BLE trae trozos de ~500 bytes)."""

    def __init__(self, al_mensaje: Callable[[bytes], None]):
        self.buf = bytearray()
        self.al_mensaje = al_mensaje

    def agregar(self, datos: bytes) -> None:
        self.buf.extend(datos)
        while len(self.buf) >= 4:
            largo = struct.unpack(">I", self.buf[:4])[0]
            if largo > MAX_MENSAJE:
                self.buf.clear()
                raise ValueError("mensaje demasiado grande")
            if len(self.buf) < 4 + largo:
                return
            msg = bytes(self.buf[4:4 + largo])
            del self.buf[:4 + largo]
            self.al_mensaje(msg)


def enmarcar(obj: Dict[str, Any]) -> bytes:
    datos = json.dumps(obj, ensure_ascii=False).encode()
    return struct.pack(">I", len(datos)) + datos


def rut_valido(rut: str) -> bool:
    """RUT chileno válido, o profesional extranjero: EXT-<país>-<registro>."""
    if re.fullmatch(r"EXT-[A-Z]{2}-[A-Z0-9./-]{3,30}", (rut or "").strip().upper()):
        return True
    limpio = re.sub(r"[.\s]", "", rut or "").upper()
    m = re.fullmatch(r"(\d{6,8})-?([\dK])", limpio)
    if not m:
        return False
    suma, mult = 0, 2
    for d in reversed(m.group(1)):
        suma += int(d) * mult
        mult = 2 if mult == 7 else mult + 1
    r = 11 - suma % 11
    return m.group(2) == ("0" if r == 11 else "K" if r == 10 else str(r))


# ══════════════════════════════════════════════════════════════
# La consulta (una a la vez)
# ══════════════════════════════════════════════════════════════
class Sesion:
    def __init__(self, enviar: Callable[[bytes], Any], medio: str):
        self.enviar_bytes = enviar
        self.medio = medio
        self.estado = "handshake"        # handshake → solicitud → aceptada → activa
        self.privada = X25519PrivateKey.generate()
        self.clave: Optional[AESGCM] = None
        self.codigo = ""
        self.paciente = ""
        self.permiso: Optional[str] = None   # permiso de consulta (transcribir / ordenar)
        self.ficha: Optional[Dict[str, Any]] = None
        self.esperas: Dict[int, asyncio.Future] = {}
        self.nota_guardada = False   # una atención por consulta (igual que la Ficha)
        self.sec = 0

    # ── cifrado ──
    def _cifrar(self, obj: Dict[str, Any]) -> Dict[str, Any]:
        nonce = os.urandom(12)
        ct = self.clave.encrypt(nonce, json.dumps(obj, ensure_ascii=False).encode(), None)
        return {"e": base64.b64encode(nonce + ct).decode()}

    def _descifrar(self, obj: Dict[str, Any]) -> Dict[str, Any]:
        raw = base64.b64decode(obj["e"])
        return json.loads(self.clave.decrypt(raw[:12], raw[12:], None))

    async def enviar(self, obj: Dict[str, Any]) -> None:
        r = self.enviar_bytes(enmarcar(self._cifrar(obj) if self.clave else obj))
        if asyncio.iscoroutine(r):
            await r

    async def pedir(self, obj: Dict[str, Any], espera: float = 25) -> Dict[str, Any]:
        """Envía y espera la confirmación del teléfono (para notas y accesos)."""
        self.sec += 1
        n = self.sec
        fut = asyncio.get_running_loop().create_future()
        self.esperas[n] = fut
        await self.enviar({**obj, "n": n})
        try:
            return await asyncio.wait_for(fut, espera)
        finally:
            self.esperas.pop(n, None)

    # ── mensajes del teléfono ──
    async def recibir(self, raw: bytes) -> None:
        obj = json.loads(raw)
        if self.clave is None:
            if obj.get("tipo") != "hola":
                return
            pub_tel = base64.b64decode(obj["pub"])
            pub_pc = self.privada.public_key().public_bytes(
                serialization.Encoding.Raw, serialization.PublicFormat.Raw)
            secreto = self.privada.exchange(X25519PublicKey.from_public_bytes(pub_tel))

            def derivar(info: bytes, largo: int) -> bytes:
                return HKDF(algorithm=hashes.SHA256(), length=largo, salt=SAL,
                            info=info + pub_tel + pub_pc).derive(secreto)

            self.clave = AESGCM(derivar(b"clave", 32))
            self.codigo = f"{int.from_bytes(derivar(b'codigo', 4), 'big') % 10000:04d}"
            self.paciente = str(obj.get("nombre") or "")[:80]
            await self.enviar_plano({"tipo": "hola", "pub": base64.b64encode(pub_pc).decode(),
                                     "equipo": NOMBRE_EQUIPO, "version": VERSION})
            self.estado = "solicitud"
            log(f"solicitud de {self.paciente} por {self.medio} · código {self.codigo}")
            abrir_navegador()
            return

        m = self._descifrar(obj)
        tipo = m.get("tipo")
        if tipo == "ficha" and self.estado == "aceptada":
            self.ficha = m.get("ficha") or {}
            self.estado = "activa"
            log("ficha recibida")
        elif tipo == "ok" and m.get("n") in self.esperas:
            fut = self.esperas[m["n"]]
            if not fut.done():
                fut.set_result(m)
        elif tipo == "permiso":
            # El teléfono tenía internet: dictar y ordenar en la página (el PC
            # no pide certificado; su página es local y ya es "segura")
            self.permiso = m.get("permiso") if isinstance(m.get("permiso"), str) else None
            log("permiso de consulta recibido")
        elif tipo == "fin":
            log("el paciente terminó la consulta")
            terminar_sesion(self)

    async def enviar_plano(self, obj: Dict[str, Any]) -> None:
        r = self.enviar_bytes(enmarcar(obj))
        if asyncio.iscoroutine(r):
            await r


ACTUAL: Optional[Sesion] = None


def nueva_sesion(enviar: Callable[[bytes], Any], medio: str) -> Optional[Sesion]:
    global ACTUAL
    if ACTUAL is not None and ACTUAL.estado != "handshake":
        return None   # ya hay una consulta en curso
    ACTUAL = Sesion(enviar, medio)
    return ACTUAL


def terminar_sesion(s: Optional[Sesion]) -> None:
    global ACTUAL
    if s is not None and ACTUAL is s:
        s.ficha = None          # la ficha sale de la memoria
        for f in s.esperas.values():
            if not f.done():
                f.cancel()
        ACTUAL = None


# ══════════════════════════════════════════════════════════════
# Red local (Wi-Fi o cable, sin internet)
# ══════════════════════════════════════════════════════════════
class Busqueda(asyncio.DatagramProtocol):
    def connection_made(self, transport):
        self.t = transport

    def datagram_received(self, data, addr):
        if data.strip() == b"HIPOKRATIA_LECTOR?":
            self.t.sendto(f"HIPOKRATIA_LECTOR {PUERTO_DATOS} {NOMBRE_EQUIPO}".encode(), addr)


async def atender_tcp(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    def enviar(b: bytes):
        writer.write(b)
        return writer.drain()

    s = nueva_sesion(enviar, "red local")
    if s is None:
        writer.close()
        return
    cola: asyncio.Queue = asyncio.Queue()
    ens = Ensamblador(cola.put_nowait)
    try:
        while True:
            datos = await reader.read(65536)
            if not datos:
                break
            ens.agregar(datos)
            while not cola.empty():
                await s.recibir(cola.get_nowait())
    except Exception as e:
        log("conexión de red cerrada:", e)
    finally:
        terminar_sesion(s)
        writer.close()


# ══════════════════════════════════════════════════════════════
# Bluetooth (BLE): el TELÉFONO se anuncia ("HypokratIA") y el PC lo busca.
# (Muchos Bluetooth de PC no pueden anunciarse; todos pueden buscar.)
# Sin emparejar nada: el PC se conecta, se suscribe y el teléfono saluda.
# ══════════════════════════════════════════════════════════════
async def bluetooth_buscar() -> None:
    try:
        from bleak import BleakClient, BleakScanner
    except Exception as e:
        log(f"Bluetooth no disponible ({type(e).__name__}: {e}); solo red local.")
        return
    log("Bluetooth listo: buscando teléfonos con HypokratIA cerca")
    recientes: Dict[str, float] = {}   # teléfono → hasta cuándo no reconectar
    loop = asyncio.get_running_loop()
    while True:
        if ACTUAL is not None:
            await asyncio.sleep(1)
            continue
        try:
            dispositivo = await BleakScanner.find_device_by_filter(
                lambda d, ad: SERVICIO_BLE in [u.lower() for u in (ad.service_uuids or [])]
                and recientes.get(d.address, 0) < loop.time(),
                timeout=4.0)
        except Exception as e:
            log(f"No se pudo buscar por Bluetooth ({type(e).__name__}: {e}); se reintenta.")
            await asyncio.sleep(5)
            continue
        if dispositivo is None:
            continue
        s: Optional[Sesion] = None
        try:
            async with BleakClient(dispositivo, timeout=15.0) as cliente:
                async def enviar(datos: bytes) -> None:
                    trozo = max(20, min(500, (getattr(cliente, "mtu_size", 23) or 23) - 3))
                    for i in range(0, len(datos), trozo):
                        await cliente.write_gatt_char(CARACT_RX, datos[i:i + trozo], response=True)

                s = nueva_sesion(enviar, "Bluetooth")
                if s is None:
                    continue
                cola: asyncio.Queue = asyncio.Queue()
                ens = Ensamblador(cola.put_nowait)
                await cliente.start_notify(CARACT_TX, lambda _c, d: ens.agregar(bytes(d)))
                log("teléfono conectado por Bluetooth")
                while cliente.is_connected and ACTUAL is s:
                    try:
                        raw = await asyncio.wait_for(cola.get(), 1.0)
                    except asyncio.TimeoutError:
                        continue
                    await s.recibir(raw)
        except Exception as e:
            log(f"Bluetooth: conexión terminada ({type(e).__name__}: {e})")
        finally:
            terminar_sesion(s)
            recientes[dispositivo.address] = loop.time() + 15


# ══════════════════════════════════════════════════════════════
# Página para el médico (solo desde este PC)
# ══════════════════════════════════════════════════════════════
# Junto al programa, o dentro del .exe (PyInstaller la desempaca en _MEIPASS)
_CARPETA = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
PAGINA = open(os.path.join(_CARPETA, "atencion.html"), encoding="utf-8").read()
_navegador_abierto = False


def abrir_navegador() -> None:
    global _navegador_abierto
    if not _navegador_abierto:
        _navegador_abierto = True
        webbrowser.open(f"http://127.0.0.1:{PUERTO_WEB}/")


def _sesion_activa() -> Sesion:
    if ACTUAL is None:
        raise web.HTTPConflict(text=json.dumps({"detail": "No hay una consulta en curso"}),
                               content_type="application/json")
    return ACTUAL


async def w_pagina(_):
    return web.Response(text=PAGINA, content_type="text/html",
                        headers={"Cache-Control": "no-store", "X-Frame-Options": "DENY"})


async def w_estado(_):
    s = ACTUAL
    if s is None or s.estado == "handshake":
        return web.json_response({"estado": "espera"})
    r = {"estado": s.estado, "paciente": s.paciente, "codigo": s.codigo}
    if s.permiso and s.estado in ("aceptada", "activa"):
        r["permiso"] = s.permiso
    return web.json_response(r)


async def w_aceptar(_):
    s = _sesion_activa()
    if s.estado == "solicitud":
        s.estado = "aceptada"
        await s.enviar({"tipo": "aceptado"})
        log("el médico aceptó")
    return web.json_response({"ok": True})


async def w_rechazar(_):
    s = _sesion_activa()
    await s.enviar({"tipo": "rechazado"})
    terminar_sesion(s)
    return web.json_response({"ok": True})


async def w_terminar(_):
    s = ACTUAL
    if s is not None:
        try:
            await s.enviar({"tipo": "fin"})
        except Exception:
            pass
        terminar_sesion(s)
    return web.json_response({"ok": True})


def _error(texto: str, codigo: int = 400):
    return web.json_response({"detail": texto}, status=codigo)


async def w_identificar(req):
    s = _sesion_activa()
    if s.ficha is None:
        return _error("Esperando la ficha del teléfono, intente en unos segundos", 409)
    b = await req.json()
    nombre, rut = str(b.get("nombre") or "").strip(), str(b.get("rut") or "").strip()
    if len(nombre) < 3 or not rut_valido(rut):
        return _error("Ingresa tu nombre completo y un RUT válido")
    try:
        await s.pedir({"tipo": "acceso", "nombre": nombre, "rut": rut})
    except (asyncio.TimeoutError, asyncio.CancelledError):
        return _error("El teléfono del paciente no respondió", 504)
    return web.json_response({"ficha": s.ficha})


async def w_nota(req):
    s = _sesion_activa()
    if s.nota_guardada:
        return _error("La atención de esta consulta ya fue guardada", 409)
    b = await req.json()
    nombre, rut = str(b.get("nombre") or "").strip(), str(b.get("rut") or "").strip()
    if len(nombre) < 3 or not rut_valido(rut):
        return _error("Falta tu nombre o RUT")
    contenido = {k: str(v) for k, v in (b.get("contenido") or {}).items()}
    try:
        r = await s.pedir({"tipo": "nota", "nombre": nombre, "rut": rut, "contenido": contenido})
    except (asyncio.TimeoutError, asyncio.CancelledError):
        return _error("El teléfono del paciente no respondió; la nota NO se guardó", 504)
    if not r.get("ok", True):
        return _error(r.get("detail") or "El teléfono no pudo guardar la nota")
    s.nota_guardada = True
    return web.json_response({"ok": True})


async def w_idioma(req):
    """El teléfono del paciente traduce la ficha (sin internet) al idioma del médico."""
    s = _sesion_activa()
    b = await req.json()
    idioma = str(b.get("idioma") or "")
    if idioma not in ("en", "de", "fr"):
        return _error("Idioma no disponible")
    try:
        r = await s.pedir({"tipo": "idioma", "idioma": idioma}, espera=240)
    except (asyncio.TimeoutError, asyncio.CancelledError):
        return _error("El teléfono no respondió a tiempo", 504)
    if not r.get("ok", True) or not isinstance(r.get("ficha"), dict):
        return _error(r.get("detail") or "El teléfono no pudo traducir")
    return web.json_response({"ficha": r["ficha"]})


_HOSTS_PROPIOS = {f"127.0.0.1:{PUERTO_WEB}", f"localhost:{PUERTO_WEB}"}
_ORIGENES_PROPIOS = {f"http://{h}" for h in _HOSTS_PROPIOS}


@web.middleware
async def solo_este_pc(req, handler):
    """Solo la página del Lector, abierta en este PC:
    - conexión desde este mismo PC;
    - Host propio (bloquea el "DNS rebinding": un sitio web que se hace pasar por 127.0.0.1);
    - en los POST, Origin propio (otra página abierta en el navegador del médico no
      puede aceptar consultas, escribir notas ni cambiar el idioma por él)."""
    if req.remote not in ("127.0.0.1", "::1"):
        raise web.HTTPForbidden()
    if req.host not in _HOSTS_PROPIOS:
        raise web.HTTPForbidden()
    if req.method != "GET" and req.headers.get("Origin") not in _ORIGENES_PROPIOS:
        raise web.HTTPForbidden()
    return await handler(req)


# ══════════════════════════════════════════════════════════════
async def main() -> None:
    loop = asyncio.get_running_loop()
    app = web.Application(middlewares=[solo_este_pc])
    app.add_routes([
        web.get("/", w_pagina), web.get("/api/estado", w_estado),
        web.post("/api/aceptar", w_aceptar), web.post("/api/rechazar", w_rechazar),
        web.post("/api/terminar", w_terminar), web.post("/api/identificar", w_identificar),
        web.post("/api/nota", w_nota), web.post("/api/idioma", w_idioma),
    ])
    runner = web.AppRunner(app, access_log=None)
    await runner.setup()
    await web.TCPSite(runner, "127.0.0.1", PUERTO_WEB).start()

    await loop.create_datagram_endpoint(Busqueda, local_addr=("0.0.0.0", PUERTO_BUSQUEDA),
                                        allow_broadcast=True)
    await asyncio.start_server(atender_tcp, "0.0.0.0", PUERTO_DATOS)
    log(f"red local lista (búsqueda {PUERTO_BUSQUEDA}/udp, datos {PUERTO_DATOS}/tcp)")
    asyncio.create_task(bluetooth_buscar())
    log(f"Lector HypokratIA {VERSION} listo en '{NOMBRE_EQUIPO}'. Página: http://127.0.0.1:{PUERTO_WEB}/")
    abrir_navegador()
    await asyncio.Event().wait()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass

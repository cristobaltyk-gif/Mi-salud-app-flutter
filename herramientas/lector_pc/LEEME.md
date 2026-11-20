# Lector HypokratIA — prototipo para el PC de la consulta

Hace en el PC lo que después hará la cajita: recibe la ficha del teléfono del
paciente **sin internet** (por Bluetooth o por la red local) y la muestra en el
navegador con la misma pantalla de **Atención Clínica** de la Ficha.

## Instalar (una vez, Windows 10/11)
1. Instalar Python 3.12 desde python.org (marcar **"Add python.exe to PATH"**).
2. Abrir esta carpeta, escribir `cmd` en la barra de dirección y Enter.
3. `pip install -r requirements.txt`

## Usar
`python lector.py` → se abre el navegador en "Esperando paciente…".
En el teléfono, sin internet: **Autorizar médico** → aceptar → huella.
Ambos muestran el mismo código de 4 números → el médico toca **ACEPTAR**.

## Seguridad
- Llaves X25519 nuevas en cada consulta, todo cifrado AES-256-GCM.
- La ficha queda solo en la memoria del programa; nada se graba en el disco.
- La página solo se abre desde este mismo PC.
- Notas y accesos vuelven al teléfono, que los sella y los sube al volver la
  red (RNPI → ficha; si no → superadmin).

Puertos: 47800/udp (búsqueda), 47801/tcp (datos), 47880 (página, solo local).
Windows puede preguntar por el Firewall la primera vez: **Permitir** en redes privadas.

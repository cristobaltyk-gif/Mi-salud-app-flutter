/// lib/widgets/tarjetas.dart — piezas únicas de diseño (mismo estilo en toda la app)
///
///  - TarjetaOpcion:  elegir una opción (A domicilio / Presencial…, Yo cuido /
///    Me cuidan…). Blanca, emoji grande, título azul en negrita y subtítulo
///    gris. Elegida: fondo celeste suave y borde azul más grueso.
///  - TarjetaPersona: una persona en una lista (profesionales, a quién cuido,
///    quién me cuida). Círculo con iniciales, nombre en negrita, detalle gris,
///    contenido extra opcional y algo a la derecha (flecha o botón).
/// Si cambia una, cambian todas las pantallas.
library;

import 'package:flutter/material.dart';

const kAzul = Color(0xFF1A3B8C);
const kBordeSuave = Color(0xFFBFDBFE);
const kFondoElegido = Color(0xFFEFF6FF);
const kTextoGris = Color(0xFF64748B);

class TarjetaOpcion extends StatelessWidget {
  final String icono;
  final String titulo;
  final String? sub;
  final bool seleccionada;
  final VoidCallback onTap;
  const TarjetaOpcion({super.key, required this.icono, required this.titulo, this.sub,
      this.seleccionada = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionada ? kFondoElegido : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: seleccionada ? kAzul : kBordeSuave, width: seleccionada ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icono, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: kAzul, fontSize: 15)),
              if ((sub ?? '').isNotEmpty)
                Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kTextoGris)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dos TarjetaOpcion por fila, con la misma separación en todas las pantallas.
class GrillaOpciones extends StatelessWidget {
  final List<Widget> opciones;
  const GrillaOpciones({super.key, required this.opciones});

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < opciones.length; i += 2) {
      if (i > 0) filas.add(const SizedBox(height: 10));
      filas.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: opciones[i]),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < opciones.length ? opciones[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: filas);
  }
}

/// "Instituto de Cirugía Articular" → ICA; "Aurora Huerta" → AH
String iniciales(String nombre) {
  final p = nombre
      .replaceFirst(RegExp(r'^(dra?|e\.u|klgo|klga|t\.o|sra?|psic)\.?\s+', caseSensitive: false), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !RegExp(r'^(de|del|la|las|los|y)$', caseSensitive: false).hasMatch(w))
      .toList();
  if (p.isEmpty) return '·';
  final t = p.length >= 3 ? p.take(3).map((w) => w[0]).join() : p[0][0] + (p.length > 1 ? p[1][0] : '');
  return t.toUpperCase();
}

class TarjetaPersona extends StatelessWidget {
  final String nombre;
  final String? detalle;
  final Color? colorDetalle;
  final List<Widget> extra;
  final Widget? derecha;
  final VoidCallback? onTap;
  const TarjetaPersona({super.key, required this.nombre, this.detalle, this.colorDetalle,
      this.extra = const [], this.derecha, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kFondoElegido,
                  child: Text(iniciales(nombre),
                      style: const TextStyle(color: kAzul, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if ((detalle ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(detalle!, style: TextStyle(fontSize: 12.5, color: colorDetalle ?? kTextoGris)),
                        ),
                      ...extra,
                    ],
                  ),
                ),
                if (derecha != null) ...[const SizedBox(width: 6), derecha!]
                else if (onTap != null) const Icon(Icons.chevron_right, color: kTextoGris),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

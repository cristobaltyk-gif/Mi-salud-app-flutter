/// lib/widgets/aviso_sin_permiso.dart
///
/// Widget compartido que se muestra dentro de un tab (Ficha, Cotizador,
/// Autorizar) cuando la carpeta seleccionada es una persona cuidada
/// cuyo nivel de acceso no alcanza para ver ese contenido (solo nivel
/// "completo" habilita Ficha/Cotizador/Autorizar -- ver
/// CarpetaActiva.esCompleto en carpeta_activa.dart).
///
/// El mensaje es especifico por tab (no generico), para que quede claro
/// que falta exactamente, en vez de un "sin acceso" ambiguo.
library;

import 'package:flutter/material.dart';

class AvisoSinPermiso extends StatelessWidget {
  final String nombrePaciente;
  final String mensaje;

  const AvisoSinPermiso({
    super.key,
    required this.nombrePaciente,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4C1D95).withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_outline, color: Color(0xFF4C1D95), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin acceso a esto para $nombrePaciente',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF4C1D95)),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.purple[300]),
            ),
          ],
        ),
      ),
    );
  }
}

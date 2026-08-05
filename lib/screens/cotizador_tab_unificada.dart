/// lib/screens/cotizador_tab_unificada.dart
///
/// Tab "Cotizador" del Dashboard con selector de carpetas. Mismo patron
/// que ficha_tab_unificada.dart: reutiliza los widgets existentes tal
/// cual, sin reescribir nada.
///   - Propia:              reusa CotizadorScreen completo.
///   - Cuidado, completo:    fetch de FichaCuidado + TabCotizadorCuidado
///                           (mismo widget que ya usa ficha_cuidado_screen.dart).
///   - Cuidado, no completo: AvisoSinPermiso.
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';
import '../models/ficha_cuidado.dart';
import '../services/ficha_service.dart';
import '../widgets/aviso_sin_permiso.dart';
import 'cotizador_screen.dart';
import 'tab_cotizador_cuidado.dart';

class CotizadorTabUnificada extends StatefulWidget {
  final CarpetaActiva carpeta;
  const CotizadorTabUnificada({super.key, required this.carpeta});

  @override
  State<CotizadorTabUnificada> createState() => _CotizadorTabUnificadaState();
}

class _CotizadorTabUnificadaState extends State<CotizadorTabUnificada> {
  Future<FichaCuidado>? _futureFicha;

  @override
  void initState() {
    super.initState();
    if (!widget.carpeta.esPropia && widget.carpeta.esCompleto) {
      _futureFicha = FichaService.obtenerFichaCuidado(widget.carpeta.rutPaciente!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.carpeta.esPropia) {
      return const CotizadorScreen();
    }

    if (!widget.carpeta.esCompleto) {
      return AvisoSinPermiso(
        nombrePaciente: widget.carpeta.nombreMostrar,
        mensaje: 'Esta persona no te dio acceso a cotizar sus medicamentos.',
      );
    }

    return FutureBuilder<FichaCuidado>(
      future: _futureFicha,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No se pudo cargar: ${snapshot.error}', textAlign: TextAlign.center),
            ),
          );
        }
        return TabCotizadorCuidado(ficha: snapshot.data!);
      },
    );
  }
}

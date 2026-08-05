/// lib/screens/ficha_tab_unificada.dart
///
/// Tab "Ficha" del Dashboard con selector de carpetas. Según la carpeta
/// activa:
///   - Propia:            reusa FichaScreen tal cual (sin duplicar su
///                         lógica interna).
///   - Cuidado, completo:  fetch de FichaCuidado + TabFichaCuidado
///                         (mismo widget que ya usa ficha_cuidado_screen.dart).
///   - Cuidado, no completo: AvisoSinPermiso.
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';
import '../models/ficha_cuidado.dart';
import '../services/ficha_service.dart';
import '../widgets/aviso_sin_permiso.dart';
import 'ficha_screen.dart';
import 'ficha_tab_cuidado.dart';

class FichaTabUnificada extends StatefulWidget {
  final CarpetaActiva carpeta;
  const FichaTabUnificada({super.key, required this.carpeta});

  @override
  State<FichaTabUnificada> createState() => _FichaTabUnificadaState();
}

class _FichaTabUnificadaState extends State<FichaTabUnificada> {
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
      return const FichaScreen();
    }

    if (!widget.carpeta.esCompleto) {
      return AvisoSinPermiso(
        nombrePaciente: widget.carpeta.nombreMostrar,
        mensaje: 'Esta persona no te dio acceso a su ficha clínica completa.',
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
        return TabFichaCuidado(
          ficha: snapshot.data!,
          rutPaciente: widget.carpeta.rutPaciente!,
        );
      },
    );
  }
}

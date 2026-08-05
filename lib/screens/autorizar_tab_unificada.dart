/// lib/screens/autorizar_tab_unificada.dart
///
/// Tab "Autorizar" del Dashboard con selector de carpetas.
///
/// Hallazgo al revisar TabAutorizarCuidado: no tiene NADA especifico de
/// "cuidado" adentro -- solo recibe un rutPaciente y muestra un boton
/// que abre CompartirFichaCuidadoScreen con ese rut. Es agnostico por
/// diseño. Eso significa que sirve igual para "Tú" (pasandole tu propio
/// rut) que para una persona cuidada -- no hace falta un widget nuevo
/// para el caso propio, solo resolver que rut pasarle:
///   - Propia:               tu propio rut (StorageService.obtenerRut()).
///   - Cuidado, completo:     rutPaciente de la carpeta.
///   - Cuidado, no completo:  AvisoSinPermiso (no se puede autorizar en
///                            nombre de alguien sin acceso completo).
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';
import '../services/storage_service.dart';
import '../widgets/aviso_sin_permiso.dart';
import 'autorizar_tab_cuidado.dart';

class AutorizarTabUnificada extends StatefulWidget {
  final CarpetaActiva carpeta;
  const AutorizarTabUnificada({super.key, required this.carpeta});

  @override
  State<AutorizarTabUnificada> createState() => _AutorizarTabUnificadaState();
}

class _AutorizarTabUnificadaState extends State<AutorizarTabUnificada> {
  Future<String?>? _futureRut;

  @override
  void initState() {
    super.initState();
    if (widget.carpeta.esPropia) {
      _futureRut = StorageService.obtenerRut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.carpeta.esPropia && !widget.carpeta.esCompleto) {
      return AvisoSinPermiso(
        nombrePaciente: widget.carpeta.nombreMostrar,
        mensaje: 'No puedes autorizar acceso médico en nombre de esta persona.',
      );
    }

    if (!widget.carpeta.esPropia) {
      // Cuidado + completo: el rut ya lo tenemos directo, sin fetch.
      return TabAutorizarCuidado(rutPaciente: widget.carpeta.rutPaciente!);
    }

    return FutureBuilder<String?>(
      future: _futureRut,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rut = snapshot.data;
        if (rut == null) {
          return const Center(child: Text('No se pudo determinar tu RUT.'));
        }
        return TabAutorizarCuidado(rutPaciente: rut);
      },
    );
  }
}

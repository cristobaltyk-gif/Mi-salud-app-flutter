/// lib/models/carpeta_activa.dart
///
/// Representa la "carpeta" seleccionada en el selector de arriba del
/// Dashboard: o bien el paciente propio ("Tú"), o una persona cuidada
/// con su nivel de acceso (medicamentos | indicaciones | completo).
///
/// Los 4 tabs unificados (ficha_tab_unificada.dart, etc.) reciben esto
/// para decidir que mostrar sin tener que repetir la logica de
/// "es propio o no" en cada uno.
library;

class CarpetaActiva {
  final bool esPropia;
  final String? rutPaciente; // null si esPropia
  final String nombreMostrar;
  final String? nivelAcceso; // null si esPropia (acceso total implicito)

  const CarpetaActiva.propia({required this.nombreMostrar})
      : esPropia = true,
        rutPaciente = null,
        nivelAcceso = null;

  const CarpetaActiva.cuidado({
    required this.rutPaciente,
    required this.nombreMostrar,
    required this.nivelAcceso,
  }) : esPropia = false;

  bool get esCompleto => esPropia || nivelAcceso == 'completo';

  /// Recordatorios estan disponibles en los 3 niveles de acceso (ver
  /// ficha_router.py: medicamentos/indicaciones/completo incluyen
  /// recordatorios) -- a diferencia de Ficha/Cotizador/Autorizar, que
  /// solo funcionan en nivel completo. Getter separado para dejar esa
  /// diferencia explicita en vez de repetir "true" a mano en cada tab.
  bool get tieneAccesoRecordatorios => true;
}

/// lib/models/carpeta_activa.dart — v1.1
///
/// Representa la "carpeta" seleccionada en el selector de arriba del
/// Dashboard: o bien el paciente propio ("Tú"), o una persona cuidada
/// con su nivel de acceso (medicamentos | indicaciones | completo).
///
/// Los 4 tabs unificados (ficha_tab_unificada.dart, etc.) reciben esto
/// para decidir que mostrar sin tener que repetir la logica de
/// "es propio o no" en cada uno.
///
/// v1.1 (mejora): tieneAccesoRecordatorios ahora compara explícitamente
/// contra los 3 niveles de acceso válidos, en vez de devolver `true`
/// sin condición. Hoy se comporta exactamente igual (son los únicos 3
/// niveles que existen), pero si en el futuro se agrega un nivel más
/// restrictivo que no deba incluir recordatorios, este getter ya no
/// lo concedería por accidente — antes, al no comparar nada, lo habría
/// seguido otorgando sin que nadie lo notara.
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
  /// solo funcionan en nivel completo.
  bool get tieneAccesoRecordatorios =>
      esPropia ||
      nivelAcceso == 'medicamentos' ||
      nivelAcceso == 'indicaciones' ||
      nivelAcceso == 'completo';
}

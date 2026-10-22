/// lib/widgets/tarjeta_visita_domicilio.dart
///
/// Tarjetas de citas agendadas (pestañas Recordatorios y Agenda):
/// - TarjetaCita: cualquier hora (presencial, domicilio, telemedicina).
/// - TarjetaVisitaDomicilio: visita a domicilio con seguimiento — estado,
///   código para el profesional, tiempo de llegada y botón al mapa.
/// Son citas, no ficha clínica.
library;

import 'package:flutter/material.dart';
import '../services/agenda_service.dart';
import '../screens/reserva_web_screen.dart';

/// Visita a domicilio: estado, código para el profesional, tiempo de llegada
/// y botón al mapa de seguimiento (se abre dentro de la app).
class TarjetaVisitaDomicilio extends StatelessWidget {
  final VisitaDomicilio visita;
  final Future<void> Function() onActualizar;
  const TarjetaVisitaDomicilio({super.key, required this.visita, required this.onActualizar});

  @override
  Widget build(BuildContext context) {
    final enCamino = visita.estado == 'en_camino';
    final llego = visita.estado == 'en_domicilio';
    final color = llego ? const Color(0xFF166534) : enCamino ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);
    final fondo = llego ? const Color(0xFFF0FDF4) : enCamino ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF);
    final titulo = llego
        ? '📍 El profesional llegó'
        : enCamino
            ? '🚗 Tu profesional va en camino'
            : '🏠 Visita a domicilio confirmada';
    final eta = enCamino ? visita.minutosRestantes : null;

    return Card(
      color: fondo,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            if (eta != null) ...[
              const SizedBox(height: 4),
              Text('Llega en aproximadamente $eta min', style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 6),
            Text('${visita.profesional} · ${visita.fecha} · ${visita.hora}',
                style: TextStyle(color: Colors.grey[800])),
            Text('📍 ${visita.direccion}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (visita.codigo != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Código para el profesional',
                        style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(visita.codigo!,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                            letterSpacing: 10, color: Color(0xFF14532D))),
                    Text('Entrégaselo cuando llegue', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
            if (!llego) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      // Mapa dentro de la app (WebView), sin salir al navegador
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ReservaWebScreen(
                            url: Uri.parse(visita.link),
                            titulo: enCamino ? 'Tu profesional va en camino' : 'Seguimiento de tu visita',
                          ),
                        ));
                        await onActualizar();
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver en el mapa'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: onActualizar,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}



/// Hora agendada. Si es a domicilio y ya tiene seguimiento, muestra la
/// tarjeta de la visita (código, mapa, tiempo de llegada).
class TarjetaCita extends StatelessWidget {
  final Cita cita;
  final Future<void> Function() onActualizar;
  /// Botones de abajo (Cambiar hora / Cancelar) — solo en la pestaña Agenda.
  final Widget? acciones;
  const TarjetaCita({super.key, required this.cita, required this.onActualizar, this.acciones});

  @override
  Widget build(BuildContext context) {
    final visita = cita.visita;
    if (visita != null && acciones == null) {
      return TarjetaVisitaDomicilio(visita: visita, onActualizar: onActualizar);
    }
    final confirmada = cita.estado == 'confirmada';
    final porConfirmar = cita.estado == 'por_confirmar';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${cita.fechaCorta} · ${cita.hora}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A3B8C))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cita.pagoPendiente || porConfirmar
                        ? const Color(0xFFFFFBEB)
                        : confirmada ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cita.pagoPendiente
                        ? 'Pendiente de pago'
                        : porConfirmar ? 'Por confirmar' : confirmada ? 'Confirmada' : 'Reservada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cita.pagoPendiente || porConfirmar
                          ? const Color(0xFFB45309)
                          : confirmada ? const Color(0xFF166534) : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(cita.profesional, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              [cita.tipoTexto, if (cita.centro.isNotEmpty) cita.centro].join(' · '),
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (cita.direccion.isNotEmpty)
              Text('📍 ${cita.direccion}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (cita.pago == 'efectivo')
              Text('💵 Pago en efectivo al profesional', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (cita.pago == 'mensual')
              Text('🗓 Convenio mensual', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (acciones != null) ...[
              const SizedBox(height: 12),
              acciones!,
            ],
          ],
        ),
      ),
    );
  }
}

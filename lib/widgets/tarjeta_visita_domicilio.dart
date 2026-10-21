/// lib/widgets/tarjeta_visita_domicilio.dart
///
/// Tarjeta de una visita a domicilio (pestaña Recordatorios): estado,
/// código para el profesional, tiempo de llegada y botón al mapa de
/// seguimiento. Es una cita, no ficha clínica.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/agenda_service.dart';

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
                      onPressed: () => launchUrl(Uri.parse(visita.link), mode: LaunchMode.inAppBrowserView),
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


/// lib/screens/tab_cotizador_cuidado.dart
///
/// Pestaña "Cotizador" dentro de FichaCuidadoScreen -- mismo patrón que
/// TabRecordatoriosCuidado / TabAutorizarCuidado (recibe la FichaCuidado
/// ya cargada por el shell, sin fetch propio).
///
/// Solo aparece si ficha.esCompleto (ver _tabsPara en
/// ficha_cuidado_screen.dart) porque medicamentosEstructurados solo
/// viene poblado en ese nivel de acceso.
///
/// DEPENDE de que EventoCuidadoCompleto tenga el campo
/// medicamentosEstructurados agregado en ficha_cuidado.dart (ver
/// modificacion aparte) -- sin eso, este archivo no compila.
library;

import 'package:flutter/material.dart';
import '../models/cotizacion.dart';
import '../models/ficha_cuidado.dart';
import 'cotizacion_detalle_screen.dart';

class TabCotizadorCuidado extends StatelessWidget {
  final FichaCuidado ficha;
  const TabCotizadorCuidado({super.key, required this.ficha});

  @override
  Widget build(BuildContext context) {
    final recetas = ficha.eventos
        .where((ev) => ev.medicamentosEstructurados.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '💊 Cotizador de medicamentos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E4A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Compara precios de las recetas de ${ficha.paciente.nombreCompleto.split(' ').first}',
          style: const TextStyle(color: Color(0xFF0F766E), fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (recetas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.medication_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no hay recetas con medicamentos\npara cotizar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Text(
            'Recetas con medicamentos (${recetas.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...recetas.map((ev) => _RecetaCardCuidado(evento: ev)),
        ],
      ],
    );
  }
}

class _RecetaCardCuidado extends StatelessWidget {
  final EventoCuidadoCompleto evento;
  const _RecetaCardCuidado({required this.evento});

  @override
  Widget build(BuildContext context) {
    final cantidad = evento.medicamentosEstructurados.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF99F6E4)),
      ),
      child: ListTile(
        leading: const Text('💊', style: TextStyle(fontSize: 22)),
        title: Text(
          evento.diagnostico.isNotEmpty ? evento.diagnostico : 'Receta médica',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${evento.fecha}'
          '${evento.medico.isNotEmpty ? " · ${evento.medico}" : ""}'
          '\n$cantidad medicamento${cantidad != 1 ? "s" : ""} — Ver cotización',
          style: const TextStyle(color: Color(0xFF0F766E), fontSize: 12.5),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF0F766E)),
        onTap: () {
          final items = evento.medicamentosEstructurados
              .map((m) => ItemReceta(principioActivo: m.medicamento, presentacion: m.dosis))
              .toList();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CotizacionDetalleScreen(
                items: items,
                titulo: evento.diagnostico.isNotEmpty ? evento.diagnostico : 'Cotización',
              ),
            ),
          );
        },
      ),
    );
  }
}

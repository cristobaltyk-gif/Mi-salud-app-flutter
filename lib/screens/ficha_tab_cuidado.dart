/// lib/screens/ficha_tab_cuidado.dart
///
/// Pestaña "Ficha" de FichaCuidadoScreen: contenido clínico según el
/// nivel de acceso autorizado (medicamentos / indicaciones / completo).
/// No incluye recordatorios ni "Autorizar médico" — cada uno vive en su
/// propio archivo/pestaña (ver recordatorios_tab_cuidado.dart y
/// autorizar_tab_cuidado.dart). El historial de consultas (nivel
/// completo) tampoco se lista acá directo — es una tarjeta-link hacia
/// HistorialConsultasCuidadoScreen, para no obnubilar esta pantalla si
/// el paciente tiene muchas consultas.
library;

import 'package:flutter/material.dart';
import '../models/ficha_cuidado.dart';
import '../widgets/estado_vacio.dart';
import 'historial_consultas_cuidado_screen.dart';

class TabFichaCuidado extends StatelessWidget {
  final FichaCuidado ficha;
  final String rutPaciente;
  const TabFichaCuidado({super.key, required this.ficha, required this.rutPaciente});

  @override
  Widget build(BuildContext context) {
    if (ficha.esMedicamentos) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          EstadoVacio(texto: 'Este nivel de acceso solo autoriza ver medicamentos y controles.\nRevisa la pestaña "Recordatorios".'),
        ],
      );
    }

    if (ficha.esIndicaciones) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Acceso autorizado: indicaciones',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          if (ficha.eventosConIndicaciones.isEmpty)
            const EstadoVacio(texto: 'Sin indicaciones registradas')
          else
            ...ficha.eventosConIndicaciones.map((ev) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.fecha, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(height: 6),
                        Text(ev.indicaciones, style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                )),
        ],
      );
    }

    if (ficha.esCompleto) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Acceso autorizado: completo',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),

          if (ficha.antecedentes != null) ...[
            Card(
              color: const Color(0xFFFFFDF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🏥', style: TextStyle(fontSize: 15)),
                        SizedBox(width: 8),
                        Text('Antecedentes médicos',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FilaAntecedente(
                      titulo: '⚠️ ALERGIAS',
                      colorTitulo: const Color(0xFFDC2626),
                      items: ficha.antecedentes!['alergia'] as List<dynamic>? ?? [],
                      vacio: 'Sin alergias conocidas',
                      colorFondo: const Color(0xFFFEF2F2),
                      colorTexto: const Color(0xFF991B1B),
                    ),
                    const SizedBox(height: 10),
                    _FilaAntecedente(
                      titulo: '💊 MEDICAMENTOS',
                      colorTitulo: const Color(0xFF1D4ED8),
                      items: ficha.antecedentes!['medicamento_habitual'] as List<dynamic>? ?? [],
                      vacio: 'Sin medicamentos habituales',
                      colorFondo: const Color(0xFFEFF6FF),
                      colorTexto: const Color(0xFF1E40AF),
                    ),
                    const SizedBox(height: 10),
                    _FilaAntecedente(
                      titulo: '🩺 CRÓNICAS',
                      colorTitulo: const Color(0xFF065F46),
                      items: ficha.antecedentes!['enfermedad_cronica'] as List<dynamic>? ?? [],
                      vacio: 'Sin enfermedades crónicas',
                      colorFondo: const Color(0xFFF0FDF4),
                      colorTexto: const Color(0xFF065F46),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _TarjetaHistorialLink(ficha: ficha, rutPaciente: rutPaciente),
        ],
      );
    }

    return const Center(child: Text('Nivel de acceso no reconocido'));
  }
}

/// Tarjeta-link hacia el historial completo de consultas — mismo
/// patrón visual que "Mi ficha clínica" en el dashboard propio.
class _TarjetaHistorialLink extends StatelessWidget {
  final FichaCuidado ficha;
  final String rutPaciente;
  const _TarjetaHistorialLink({required this.ficha, required this.rutPaciente});

  @override
  Widget build(BuildContext context) {
    final n = ficha.eventos.length;
    final subtitulo = n == 0
        ? 'Sin consultas registradas'
        : '$n consulta${n == 1 ? '' : 's'} registrada${n == 1 ? '' : 's'}';

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistorialConsultasCuidadoScreen(
                rutPaciente: rutPaciente,
                nombrePaciente: ficha.paciente.nombreCompleto,
                eventos: ficha.eventos,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Color(0xFF0F766E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Historial de consultas',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF134E4A))),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaAntecedente extends StatelessWidget {
  final String titulo;
  final Color colorTitulo;
  final List<dynamic> items;
  final String vacio;
  final Color colorFondo;
  final Color colorTexto;

  const _FilaAntecedente({
    required this.titulo,
    required this.colorTitulo,
    required this.items,
    required this.vacio,
    required this.colorFondo,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                letterSpacing: 0.8, color: colorTitulo)),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Text(vacio,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic)),
          )
        else
          ...items.map((it) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: colorFondo, borderRadius: BorderRadius.circular(8)),
                child: Text('${(it as Map)['descripcion'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: colorTexto, fontWeight: FontWeight.w500)),
              )),
      ],
    );
  }
}

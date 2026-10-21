/// lib/screens/agendar_screen.dart
///
/// "Agendar hora": A domicilio | Presencial.
/// 1. Centros que ofrecen esa modalidad.
/// 2. Dentro de cada centro, sus profesionales con su especialidad.
/// 3. "Agendar" abre la página de reservas del centro en el navegador, con
///    el profesional ya elegido (mismo flujo que la web: horas reales,
///    dirección registrada, pago en línea con el Flow del centro).
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/agenda_service.dart';
import '../widgets/etiqueta_especialidad.dart';

const _azul = Color(0xFF1A3B8C);
const _verde = Color(0xFF0F766E);

class AgendarScreen extends StatefulWidget {
  final String modalidadInicial; // 'domicilio' | 'presencial'
  /// Cuidador agendando para la persona que cuida: se le recuerda usar
  /// el RUT de esa persona en la página de reservas.
  final String? paraNombre;
  const AgendarScreen({super.key, this.modalidadInicial = 'domicilio', this.paraNombre});

  @override
  State<AgendarScreen> createState() => _AgendarScreenState();
}

class _AgendarScreenState extends State<AgendarScreen> {
  late String _modalidad;
  Future<List<CentroAgenda>>? _futureCentros;

  @override
  void initState() {
    super.initState();
    _modalidad = widget.modalidadInicial == 'presencial' ? 'presencial' : 'domicilio';
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureCentros = AgendaService.centros(_modalidad);
    });
  }

  void _cambiarModalidad(String m) {
    if (m == _modalidad) return;
    _modalidad = m;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(widget.paraNombre == null ? 'Agendar hora' : 'Agendar para ${widget.paraNombre}'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(child: _BotonModalidad(
                  texto: '🏠 A domicilio',
                  activo: _modalidad == 'domicilio',
                  onTap: () => _cambiarModalidad('domicilio'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _BotonModalidad(
                  texto: '🏥 Presencial',
                  activo: _modalidad == 'presencial',
                  onTap: () => _cambiarModalidad('presencial'),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _modalidad == 'domicilio'
                  ? 'Un profesional te atiende en tu casa. El pago es en línea al reservar.'
                  : 'Reserva tu hora en uno de nuestros centros.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          if (widget.paraNombre != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Estás agendando para ${widget.paraNombre}. En la reserva, ingresa su RUT (no el tuyo).',
                style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<CentroAgenda>>(
              future: _futureCentros,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                        ],
                      ),
                    ),
                  );
                }
                final centros = snapshot.data ?? [];
                if (centros.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _modalidad == 'domicilio'
                            ? 'Por ahora no hay centros con atención a domicilio disponibles.'
                            : 'Por ahora no hay centros con atención presencial disponibles.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: centros.map((c) => _TarjetaCentro(centro: c, modalidad: _modalidad)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonModalidad extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  const _BotonModalidad({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFF0FDF9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? _verde : const Color(0xFFE2E8F0)),
        ),
        child: Text(texto,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: activo ? _verde : Colors.grey[700],
            )),
      ),
    );
  }
}

class _TarjetaCentro extends StatelessWidget {
  final CentroAgenda centro;
  final String modalidad;
  const _TarjetaCentro({required this.centro, required this.modalidad});

  Future<void> _agendar(BuildContext context, ProfesionalAgenda p) async {
    final ok = await launchUrl(centro.urlReservaDe(p), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la página de reservas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = centro.profesionales.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(centro.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$n ${n == 1 ? 'profesional' : 'profesionales'}${centro.soloDomicilio ? ' · Solo a domicilio' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: centro.profesionales.map((p) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      EtiquetaEspecialidad(especialidad: p.etiqueta),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _verde),
                  onPressed: () => _agendar(context, p),
                  child: const Text('Agendar'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

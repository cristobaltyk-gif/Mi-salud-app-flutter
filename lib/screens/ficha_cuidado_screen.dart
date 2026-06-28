/// lib/screens/ficha_cuidado_screen.dart
///
/// Vista de la ficha de un paciente cuidado. El RUT llega como argumento
/// de navegación (no desde storage), igual que en la web.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ficha_cuidado.dart';
import '../models/recordatorio.dart';
import '../services/ficha_service.dart';
import 'compartir_ficha_cuidado_screen.dart';

class FichaCuidadoScreen extends StatefulWidget {
  final String rutPaciente;

  const FichaCuidadoScreen({super.key, required this.rutPaciente});

  @override
  State<FichaCuidadoScreen> createState() => _FichaCuidadoScreenState();
}

class _FichaCuidadoScreenState extends State<FichaCuidadoScreen> {
  Future<FichaCuidado>? _futureFicha;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() => _futureFicha = FichaService.obtenerFichaCuidado(widget.rutPaciente));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<FichaCuidado>(
          future: _futureFicha,
          builder: (context, snapshot) {
            final nombrePaciente = snapshot.data?.paciente.nombreCompleto;

            return Column(
              children: [
                _BannerModoCuidador(nombrePaciente: nombrePaciente),
                AppBar(
                  title: Text(nombrePaciente ?? 'Ficha del paciente'),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                Expanded(
                  child: _buildContenido(snapshot),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContenido(AsyncSnapshot<FichaCuidado> snapshot) {
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
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 12),
              Text('${snapshot.error}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final ficha = snapshot.data!;

    if (ficha.esMedicamentos) return _VistaMedicamentos(ficha: ficha);
    if (ficha.esIndicaciones) return _VistaIndicaciones(ficha: ficha);
    if (ficha.esCompleto) {
      return _VistaCompleta(ficha: ficha, rutPaciente: widget.rutPaciente);
    }
    return const Center(child: Text('Nivel de acceso no reconocido'));
  }
}

class _BannerModoCuidador extends StatelessWidget {
  final String? nombrePaciente;
  const _BannerModoCuidador({this.nombrePaciente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF4C1D95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Modo cuidador',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (nombrePaciente != null)
                    TextSpan(
                      text: ' · Viendo la ficha de $nombrePaciente',
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _VistaMedicamentos extends StatelessWidget {
  final FichaCuidado ficha;
  const _VistaMedicamentos({required this.ficha});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Acceso autorizado: medicamentos y controles',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        if (ficha.recordatorios.isEmpty)
          _EstadoVacio(texto: 'Sin medicamentos ni controles vigentes')
        else
          ...ficha.recordatorios.map((r) => _TarjetaRecordatorio(r: r)),
      ],
    );
  }
}

class _VistaIndicaciones extends StatelessWidget {
  final FichaCuidado ficha;
  const _VistaIndicaciones({required this.ficha});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Acceso autorizado: medicamentos, controles e indicaciones',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        if (ficha.recordatorios.isEmpty)
          _EstadoVacio(texto: 'Sin medicamentos ni controles vigentes')
        else
          ...ficha.recordatorios.map((r) => _TarjetaRecordatorio(r: r)),
        if (ficha.eventosConIndicaciones.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Indicaciones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
      ],
    );
  }
}

class _VistaCompleta extends StatelessWidget {
  final FichaCuidado ficha;
  final String rutPaciente;
  const _VistaCompleta({required this.ficha, required this.rutPaciente});

  @override
  Widget build(BuildContext context) {
    final alergias = (ficha.antecedentes?['alergia'] as List<dynamic>? ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Acceso autorizado: completo',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),

        Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: rutPaciente),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF4C1D95)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Autorizar acceso a médico',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple[800])),
                        const SizedBox(height: 2),
                        Text(
                          'Genera un acceso temporal para que un médico revise esta ficha',
                          style: TextStyle(fontSize: 12, color: Colors.purple[300]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (alergias.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ ALERGIAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  ...alergias.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${(a as Map)['descripcion'] ?? ''}'),
                      )),
                ],
              ),
            ),
          ),
        ],

        if (ficha.recordatorios.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Medicamentos y controles', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ficha.recordatorios.map((r) => _TarjetaRecordatorio(r: r)),
        ],

        const SizedBox(height: 16),
        Text('Historial de consultas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (ficha.eventos.isEmpty)
          Text('Sin consultas registradas', style: TextStyle(color: Colors.grey[500]))
        else
          ...ficha.eventos.map((ev) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(ev.diagnostico.isNotEmpty ? ev.diagnostico : ev.tipo),
                  subtitle: Text('${ev.fecha} · ${ev.medico}'),
                ),
              )),
      ],
    );
  }
}

class _TarjetaRecordatorio extends StatelessWidget {
  final Recordatorio r;
  const _TarjetaRecordatorio({required this.r});

  @override
  Widget build(BuildContext context) {
    final proxima = r.proximoDisparo != null
        ? DateFormat('EEE HH:mm', 'es').format(r.proximoDisparo!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.textoMostrar, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (proxima != null) ...[
              const SizedBox(height: 4),
              Text('⏰ Próxima toma: $proxima',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF14B8A6))),
            ],
            if (r.frecuenciaHoras != null) ...[
              const SizedBox(height: 2),
              Text(
                'Cada ${r.frecuenciaHoras}h${r.duracionDias != null ? ' · ${r.duracionDias} días de tratamiento' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String texto;
  const _EstadoVacio({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(texto, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }
}

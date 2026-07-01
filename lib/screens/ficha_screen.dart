/// lib/screens/ficha_screen.dart
library;

import 'package:flutter/material.dart';
import '../models/evento_clinico.dart';
import '../services/ficha_service.dart';
import '../services/storage_service.dart';
import 'evento_detalle_screen.dart';
import 'compartir_ficha_cuidado_screen.dart';

class FichaScreen extends StatefulWidget {
  const FichaScreen({super.key});
  @override
  State<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends State<FichaScreen> {
  Future<FichaResumen>? _futureResumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() { _futureResumen = FichaService.obtenerResumen(); });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _cargar(),
      child: FutureBuilder<FichaResumen>(
        future: _futureResumen,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorConReintentar(
              mensaje: 'No se pudo cargar tu ficha: ${snapshot.error}',
              onReintentar: _cargar,
            );
          }
          final resumen = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hola, ${resumen.paciente.nombreCompleto.split(' ').first} 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E4A),
                    ),
              ),
              const SizedBox(height: 4),
              Text('¿Cómo te sientes hoy?',
                  style: TextStyle(color: const Color(0xFF0F766E), fontSize: 14)),
              const SizedBox(height: 16),
              _SeccionAntecedentesCriticos(antecedentes: resumen.antecedentes),
              const SizedBox(height: 12),
              _BotonAcceso(
                icono: '📋',
                titulo: 'Mi ficha clínica',
                subtitulo: 'Revisa tu historial médico explicado en lenguaje simple',
                color: const Color(0xFF0F766E),
                colorBorde: const Color(0xFF99F6E4),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConsultasScreen(resumen: resumen, onExplicar: _abrirExplicacionGeneral),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _BotonAcceso(
                icono: '🔐',
                titulo: 'Autorizar acceso a médico',
                subtitulo: 'Genera un acceso temporal para que un médico externo revise tu ficha',
                color: const Color(0xFF4C1D95),
                colorBorde: const Color(0xFFDDD6FE),
                onTap: () async {
                  final rut = await StorageService.obtenerRut();
                  if (!context.mounted || rut == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: rut),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _abrirExplicacionGeneral(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExplicacionSheet(
        titulo: 'Tu historial, explicado simple',
        stream: FichaService.explicarFicha(),
      ),
    );
  }
}

class _SeccionAntecedentesCriticos extends StatelessWidget {
  final Map<String, dynamic> antecedentes;
  const _SeccionAntecedentesCriticos({required this.antecedentes});

  List<dynamic> _items(String key) => antecedentes[key] as List<dynamic>? ?? [];

  @override
  Widget build(BuildContext context) {
    final alergias = _items('alergia');
    final medicamentos = _items('medicamento_habitual');
    final cronicas = _items('enfermedad_cronica');

    return Card(
      color: const Color(0xFFFFFDF0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🏥', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('Información médica importante',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            _CategoriaCritica(
              titulo: '⚠️ Alergias',
              colorTitulo: const Color(0xFFDC2626),
              items: alergias,
              colorTarjeta: const Color(0xFFFEF2F2),
              colorTextoTarjeta: const Color(0xFF991B1B),
              mensajeVacio: 'Sin alergias conocidas registradas',
            ),
            const SizedBox(height: 12),
            _CategoriaCritica(
              titulo: '💊 Medicamentos habituales',
              colorTitulo: const Color(0xFF1D4ED8),
              items: medicamentos,
              colorTarjeta: const Color(0xFFEFF6FF),
              colorTextoTarjeta: const Color(0xFF1E40AF),
              mensajeVacio: 'Sin medicamentos habituales registrados',
            ),
            const SizedBox(height: 12),
            _CategoriaCritica(
              titulo: '🩺 Enfermedades crónicas',
              colorTitulo: const Color(0xFF065F46),
              items: cronicas,
              colorTarjeta: const Color(0xFFF0FDF4),
              colorTextoTarjeta: const Color(0xFF065F46),
              mensajeVacio: 'Sin enfermedades crónicas registradas',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF9C3),
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AntecedentesScreen(antecedentes: antecedentes),
                  ),
                ),
                child: const Text('Ver todos mis antecedentes →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaCritica extends StatelessWidget {
  final String titulo;
  final Color colorTitulo;
  final List<dynamic> items;
  final Color colorTarjeta;
  final Color colorTextoTarjeta;
  final String mensajeVacio;

  const _CategoriaCritica({
    required this.titulo,
    required this.colorTitulo,
    required this.items,
    required this.colorTarjeta,
    required this.colorTextoTarjeta,
    required this.mensajeVacio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                letterSpacing: 0.8, color: colorTitulo)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          _TarjetaTexto(
            texto: mensajeVacio,
            color: const Color(0xFFF8FAFC),
            colorTexto: const Color(0xFF94A3B8),
            italica: true,
          )
        else
          ...items.map((it) => _TarjetaTexto(
                texto: '${(it as Map)['descripcion'] ?? ''}',
                color: colorTarjeta,
                colorTexto: colorTextoTarjeta,
              )),
      ],
    );
  }
}

class _TarjetaTexto extends StatelessWidget {
  final String texto;
  final Color color;
  final Color colorTexto;
  final bool italica;

  const _TarjetaTexto({
    required this.texto,
    required this.color,
    required this.colorTexto,
    this.italica = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(texto,
          style: TextStyle(
            fontSize: 13,
            color: colorTexto,
            fontStyle: italica ? FontStyle.italic : FontStyle.normal,
            fontWeight: italica ? FontWeight.normal : FontWeight.w500,
          )),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final EventoClinico evento;
  const _EventoCard({required this.evento});

  IconData get _icono {
    switch (evento.tipo) {
      case 'control': return Icons.event_available_outlined;
      case 'cirugia': return Icons.medical_services_outlined;
      default: return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icono, color: const Color(0xFF2563EB)),
        title: Text(
          evento.diagnostico.isNotEmpty ? evento.diagnostico : evento.tipo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${evento.fecha} · ${evento.medico}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventoDetalleScreen(evento: evento)),
        ),
      ),
    );
  }
}
class _ExplicacionSheet extends StatefulWidget {
  final String titulo;
  final Stream<ExplicacionEvento> stream;

  const _ExplicacionSheet({required this.titulo, required this.stream});

  @override
  State<_ExplicacionSheet> createState() => _ExplicacionSheetState();
}

class _ExplicacionSheetState extends State<_ExplicacionSheet> {
  final StringBuffer _texto = StringBuffer();
  String? _error;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      (evento) {
        if (!mounted) return;
        setState(() {
          switch (evento) {
            case ExplicacionTexto(texto: final t):
              _texto.write(t);
            case ExplicacionError(mensaje: final m):
              _error = m;
            case ExplicacionDone():
              _terminado = true;
          }
        });
      },
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.titulo, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(_texto.toString(),
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                ),
              if (!_terminado && _error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorConReintentar extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorConReintentar({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _BotonAcceso extends StatelessWidget {
  final String icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color colorBorde;
  final VoidCallback onTap;

  const _BotonAcceso({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.colorBorde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBorde),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(fontWeight: FontWeight.w600,
                            color: color, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsultasScreen extends StatelessWidget {
  final FichaResumen resumen;
  final void Function(BuildContext) onExplicar;

  const ConsultasScreen({
    super.key,
    required this.resumen,
    required this.onExplicar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi ficha clínica'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resumen.paciente.nombreCompleto,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${resumen.totalConsultas} consultas registradas'
                    '${resumen.ultimaConsulta != null ? " · última: ${resumen.ultimaConsulta}" : ""}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => onExplicar(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Explícame mi historial en simple'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tus consultas (${resumen.totalConsultas})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (resumen.eventos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aún no tienes consultas registradas',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            )
          else
            ...resumen.eventos.map((ev) => _EventoCard(evento: ev)),
        ],
      ),
    );
  }
}

class AntecedentesScreen extends StatelessWidget {
  final Map<String, dynamic> antecedentes;
  const AntecedentesScreen({super.key, required this.antecedentes});

  static const _categorias = [
    ('enfermedad_cronica', '🩺 Enfermedades crónicas', 'Sin enfermedades crónicas registradas'),
    ('cirugia', '🔬 Cirugías', 'Sin cirugías registradas'),
    ('alergia', '⚠️ Alergias', 'Sin alergias conocidas registradas'),
    ('medicamento_habitual', '💊 Medicamentos habituales', 'Sin medicamentos habituales registrados'),
    ('antecedente_familiar', '👨‍👩‍👧 Antecedentes familiares', 'Sin antecedentes familiares registrados'),
    ('otro', '📋 Otros antecedentes', 'Sin otros antecedentes registrados'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis antecedentes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _categorias.map((cat) {
          final (key, titulo, vacioLabel) = cat;
          final items = antecedentes[key] as List<dynamic>? ?? [];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          color: Color(0xFF134E4A))),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    _TarjetaTexto(
                      texto: vacioLabel,
                      color: const Color(0xFFF8FAFC),
                      colorTexto: const Color(0xFF94A3B8),
                      italica: true,
                    )
                  else
                    ...items.map((it) {
                      final m = it as Map;
                      final descripcion = m['descripcion'] ?? '';
                      final fechaInicio = m['fecha_inicio'];
                      final registradoPor = m['registrado_por'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$descripcion',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF134E4A))),
                            if (fechaInicio != null || registradoPor != null) ...[
                              const SizedBox(height: 4),
                              Wrap(spacing: 8, children: [
                                if (fechaInicio != null)
                                  Text('Desde $fechaInicio',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF5EEAD4))),
                                if (registradoPor != null)
                                  Text('· $registradoPor',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ]),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

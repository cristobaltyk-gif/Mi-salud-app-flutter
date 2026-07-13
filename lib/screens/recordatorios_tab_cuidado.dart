/// lib/screens/recordatorios_tab_cuidado.dart
///
/// Pestaña "Recordatorios" de FichaCuidadoScreen: medicamentos y
/// controles vigentes de este paciente cuidado, como listado propio y
/// simple — sin mezclarse con antecedentes, historial, ni autorizar
/// médico (cada uno vive en su propio archivo).
///
/// v1.1 — Las tarjetas de recordatorios tipo 'ejercicio' (plan
/// domiciliario de kinesiología, con mediaPath no vacío) ahora son
/// tocables: al tocarlas, abren MediaEjercicioScreen con la misma foto
/// o video que se muestra al tocar la notificación — así el cuidador
/// puede volver a ver el ejercicio indicado al paciente cuidado
/// cuando quiera. El resto de los tipos (medicamento, control,
/// indicación) no cambia.
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ficha_cuidado.dart';
import '../models/recordatorio.dart';
import '../widgets/estado_vacio.dart';
import 'media_ejercicio_screen.dart';
class TabRecordatoriosCuidado extends StatelessWidget {
  final FichaCuidado ficha;
  const TabRecordatoriosCuidado({super.key, required this.ficha});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ficha.recordatorios.isEmpty)
          const EstadoVacio(texto: 'Sin medicamentos ni controles vigentes')
        else
          ...ficha.recordatorios.map((r) => _TarjetaRecordatorio(r: r)),
      ],
    );
  }
}
class _TarjetaRecordatorio extends StatelessWidget {
  final Recordatorio r;
  const _TarjetaRecordatorio({required this.r});

  void _abrirMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaEjercicioScreen(
          titulo: r.descripcion,
          cuerpo: r.textoMostrar,
          mediaPath: r.mediaPath!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxima = r.proximoDisparo != null
        ? DateFormat('EEE HH:mm', 'es').format(r.proximoDisparo!)
        : null;
    final tieneMedia = r.tipo == 'ejercicio' && r.mediaPath != null && r.mediaPath!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: tieneMedia ? () => _abrirMedia(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              if (tieneMedia)
                const Icon(Icons.play_circle_outline, color: Color(0xFF0F766E), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

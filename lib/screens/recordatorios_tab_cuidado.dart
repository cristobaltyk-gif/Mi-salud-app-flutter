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
///
/// v1.2 — Se muestra la relación (recordatorio.pacienteRelacion, ej.
/// "hija") en un badge chico junto al título, cuando el backend la
/// trae. Si no viene (null), no se muestra nada extra — esta pestaña
/// ya es de un solo paciente cuidado, así que el badge es solo un
/// recordatorio del vínculo, no una distinción entre varios pacientes.
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

  static const _colorCuidado = Color(0xFF6D28D9);
  static const _colorCuidadoFondo = Color(0xFFF5F3FF);

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
    final tieneRelacion = r.pacienteRelacion != null && r.pacienteRelacion!.isNotEmpty;

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
                    if (tieneRelacion) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _colorCuidadoFondo,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _colorCuidado.withOpacity(0.3)),
                        ),
                        child: Text(
                          r.pacienteRelacion!,
                          style: const TextStyle(
                            color: _colorCuidado, fontSize: 11, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
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

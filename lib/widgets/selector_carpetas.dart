/// lib/widgets/selector_carpetas.dart
///
/// Fila horizontal scrolleable arriba del Dashboard, tipo pestañas de
/// carpeta: "Tú" + una por cada persona cuidada. Al tocar una, cambia
/// que datos ven los 4 tabs de abajo (ver *_tab_unificada.dart).
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';

class SelectorCarpetas extends StatelessWidget {
  final List<CarpetaActiva> carpetas;
  final int indiceActivo;
  final ValueChanged<int> onSeleccionar;

  const SelectorCarpetas({
    super.key,
    required this.carpetas,
    required this.indiceActivo,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    if (carpetas.length <= 1) {
      // Si no cuidas a nadie (o nadie te cuida a ti confirmado), no
      // tiene sentido mostrar un selector con una sola opcion fija.
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFF1A3B8C),
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: carpetas.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final carpeta = carpetas[i];
            final activo = i == indiceActivo;
            return GestureDetector(
              onTap: () => onSeleccionar(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activo ? Colors.white : Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      carpeta.esPropia ? Icons.person : Icons.people_alt_outlined,
                      size: 15,
                      color: activo ? const Color(0xFF1A3B8C) : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      carpeta.nombreMostrar,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                        color: activo ? const Color(0xFF1A3B8C) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

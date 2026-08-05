/// lib/widgets/barra_inferior_tabs.dart
///
/// Tab bar inferior reutilizable. Antes este mismo widget (Container +
/// Row + GestureDetector + AnimatedContainer) estaba duplicado casi
/// idéntico en dashboard_screen.dart (_tabs) y ficha_cuidado_screen.dart
/// (_BarraInferior) -- se unifica aca en un solo lugar.
///
/// El color es parametrizable porque Dashboard usa azul (#1A3B8C, marca
/// HypokratIA) y FichaCuidado usa verde (#0F766E, mismo verde que el
/// resto de las pantallas de "modo cuidador").
library;

import 'package:flutter/material.dart';

class TabInfo {
  final IconData icono;
  final IconData iconoActivo;
  final String label;
  const TabInfo({required this.icono, required this.iconoActivo, required this.label});
}

class BarraInferiorTabs extends StatelessWidget {
  final List<TabInfo> tabs;
  final int tabActual;
  final Color color;
  final void Function(int index) onTap;

  const BarraInferiorTabs({
    super.key,
    required this.tabs,
    required this.tabActual,
    required this.onTap,
    this.color = const Color(0xFF1A3B8C),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final activo = tabActual == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    // Mismo ajuste de contraste que se hizo en dashboard_screen.dart.
                    color: activo ? color.withOpacity(0.16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activo ? tab.iconoActivo : tab.icono,
                        color: activo ? color : Colors.grey[700],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
                            color: activo ? color : Colors.grey[700],
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

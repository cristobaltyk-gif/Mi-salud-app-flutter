/// lib/screens/ficha_cuidado_screen.dart
///
/// Vista de la ficha de un paciente cuidado. El RUT llega como argumento
/// de navegación (no desde storage), igual que en la web.
///
/// v1.1: nivel "completo" ahora usa _EventoCard con detalle expandible,
/// descarga/apertura de PDF (open_file), y galería de fotos — igual
/// funcionalidad que EventoCard en Ficha.jsx / FichaCuidado.jsx de la
/// web. Antes solo mostraba un ListTile plano (diagnóstico + fecha).
///
/// v1.2 — Antes todo (antecedentes, recordatorios, historial, autorizar
/// médico) se apilaba en un solo ListView largo, mezclado. Ahora la
/// pantalla tiene una barra de pestañas abajo, igual estilo que
/// dashboard_screen.dart: "Ficha", "Recordatorios" y "Autorizar médico"
/// (solo si el nivel es completo).
///
/// v1.3 — El historial de consultas (nivel completo) todavía apilaba
/// TODAS las consultas en la primera pantalla de la pestaña Ficha. Se
/// mueve a su propia pantalla (historial_consultas_cuidado_screen.dart),
/// alcanzable desde una tarjeta-link.
///
/// v1.4 — Este archivo era un solo bloque de ~600 líneas con las tres
/// pestañas apiladas dentro. Se separa en 4 archivos, cada uno con una
/// sola responsabilidad, mismo patrón que ya usa el dashboard propio
/// (dashboard_screen.dart delega a recordatorios_screen.dart, etc.):
///   - ficha_tab_cuidado.dart:         pestaña "Ficha"
///   - recordatorios_tab_cuidado.dart: pestaña "Recordatorios"
///   - autorizar_tab_cuidado.dart:     pestaña "Autorizar médico"
///   - widgets/estado_vacio.dart:      widget compartido (antes duplicado)
/// Este archivo queda como el "shell": banner, AppBar, barra de
/// pestañas abajo, y la carga de la ficha — sin contenido propio de
/// ninguna pestaña.
library;

import 'package:flutter/material.dart';
import '../models/ficha_cuidado.dart';
import '../services/ficha_service.dart';
import 'ficha_tab_cuidado.dart';
import 'recordatorios_tab_cuidado.dart';
import 'autorizar_tab_cuidado.dart';

class FichaCuidadoScreen extends StatefulWidget {
  final String rutPaciente;

  const FichaCuidadoScreen({super.key, required this.rutPaciente});

  @override
  State<FichaCuidadoScreen> createState() => _FichaCuidadoScreenState();
}

class _TabInfo {
  final IconData icono;
  final IconData iconoActivo;
  final String label;
  const _TabInfo({required this.icono, required this.iconoActivo, required this.label});
}

class _FichaCuidadoScreenState extends State<FichaCuidadoScreen> {
  Future<FichaCuidado>? _futureFicha;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _tabActual = 0;
      _futureFicha = FichaService.obtenerFichaCuidado(widget.rutPaciente);
    });
  }

  List<_TabInfo> _tabsPara(FichaCuidado ficha) {
    return [
      const _TabInfo(icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
      const _TabInfo(icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
      if (ficha.esCompleto)
        const _TabInfo(icono: Icons.lock_outline, iconoActivo: Icons.lock, label: 'Autorizar'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FichaCuidado>(
      future: _futureFicha,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const _BannerModoCuidador(nombrePaciente: null),
                  AppBar(
                    title: const Text('Ficha del paciente'),
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                  Expanded(
                    child: Center(
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
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ficha = snapshot.data!;
        final tabs = _tabsPara(ficha);
        final tabActual = _tabActual < tabs.length ? _tabActual : 0;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _BannerModoCuidador(nombrePaciente: ficha.paciente.nombreCompleto),
                AppBar(
                  title: Text(ficha.paciente.nombreCompleto),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                Expanded(
                  child: _buildTab(tabActual, ficha),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BarraInferior(
            tabs: tabs,
            tabActual: tabActual,
            onTap: (i) => setState(() => _tabActual = i),
          ),
        );
      },
    );
  }

  Widget _buildTab(int index, FichaCuidado ficha) {
    switch (index) {
      case 0:
        return TabFichaCuidado(ficha: ficha, rutPaciente: widget.rutPaciente);
      case 1:
        return TabRecordatoriosCuidado(ficha: ficha);
      case 2:
        return TabAutorizarCuidado(rutPaciente: widget.rutPaciente);
      default:
        return TabFichaCuidado(ficha: ficha, rutPaciente: widget.rutPaciente);
    }
  }
}

class _BarraInferior extends StatelessWidget {
  final List<_TabInfo> tabs;
  final int tabActual;
  final ValueChanged<int> onTap;

  const _BarraInferior({required this.tabs, required this.tabActual, required this.onTap});

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: activo ? const Color(0xFF0F766E).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activo ? tab.iconoActivo : tab.icono,
                        color: activo ? const Color(0xFF0F766E) : Colors.grey[500],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.normal,
                            color: activo ? const Color(0xFF0F766E) : Colors.grey[500],
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

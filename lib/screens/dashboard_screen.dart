/// lib/screens/dashboard_screen.dart
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import 'ficha_screen.dart';
import 'recordatorios_screen.dart';
import 'cuidador_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabActual = 0;
  bool _sincronizando = true;
  String? _errorSincronizacion;

  @override
  void initState() {
    super.initState();
    _sincronizarAlarmas();
  }

  Future<void> _sincronizarAlarmas() async {
    setState(() {
      _sincronizando = true;
      _errorSincronizacion = null;
    });
    try {
      await AlarmService.pedirPermisos();
      final recordatorios = await RecordatoriosService.misRecordatorios();
      await AlarmService.reprogramarTodas(recordatorios);
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('401') && !msg.contains('sesión')) {
        setState(() => _errorSincronizacion = msg);
      }
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await AlarmService.cancelarTodas();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static const _tabs = [
    (icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
    (icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
    (icono: Icons.people_outline, iconoActivo: Icons.people, label: 'Cuidadores'),
  ];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const FichaScreen(),
      RecordatoriosScreen(onRecordatoriosCambiaron: _sincronizarAlarmas),
      const CuidadorScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B8C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/hypokratia_icon.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 8),
            const Text('HypokratIA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        actions: [
          if (_sincronizando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorSincronizacion != null)
            Container(
              width: double.infinity,
              color: Colors.orange[50],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange[800], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('No se pudieron actualizar las alarmas',
                        style: TextStyle(color: Colors.orange[900], fontSize: 12)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.orange[800]),
                    onPressed: _sincronizarAlarmas,
                    child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(child: paginas[_tabActual]),
        ],
      ),
      bottomNavigationBar: Container(
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
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final activo = _tabActual == i;
                return GestureDetector(
                  onTap: () => setState(() => _tabActual = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: activo ? const Color(0xFF1A3B8C).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activo ? tab.iconoActivo : tab.icono,
                          color: activo ? const Color(0xFF1A3B8C) : Colors.grey[500],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: activo ? FontWeight.w700 : FontWeight.normal,
                              color: activo ? const Color(0xFF1A3B8C) : Colors.grey[500],
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

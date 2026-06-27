/// lib/screens/dashboard_screen.dart
///
/// Pantalla principal con navegación inferior de 3 pestañas. Al entrar,
/// sincroniza los recordatorios vigentes con el backend y reprograma TODAS
/// las alarmas locales — así la app siempre refleja el horario más
/// reciente, sin depender de que llegue ningún push del servidor.
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

  /// Trae los recordatorios vigentes del backend y reprograma TODAS las
  /// alarmas locales a partir de ahí. Cancela las anteriores primero
  /// (ver AlarmService.reprogramarTodas) para no duplicar notificaciones
  /// si esta pantalla se vuelve a abrir varias veces.
  Future<void> _sincronizarAlarmas() async {
    setState(() {
      _sincronizando = true;
      _errorSincronizacion = null;
    });

    try {
      // Permisos de notificación/alarma exacta — se pide acá, la primera
      // vez que el paciente entra al dashboard, con contexto (ya inició
      // sesión, ya sabe que la app maneja sus medicamentos).
      await AlarmService.pedirPermisos();

      final recordatorios = await RecordatoriosService.misRecordatorios();
      await AlarmService.reprogramarTodas(recordatorios);
    } catch (e) {
      setState(() => _errorSincronizacion = e.toString());
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
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

  static const _titulos = ['Mi Ficha', 'Mis Recordatorios', 'Cuidadores'];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const FichaScreen(),
      RecordatoriosScreen(onRecordatoriosCambiaron: _sincronizarAlarmas),
      const CuidadorScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_tabActual]),
        actions: [
          if (_sincronizando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se pudieron actualizar las alarmas: $_errorSincronizacion',
                      style: TextStyle(color: Colors.orange[900], fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _sincronizarAlarmas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(child: paginas[_tabActual]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder_shared_outlined), label: 'Ficha'),
          NavigationDestination(icon: Icon(Icons.alarm_outlined), label: 'Recordatorios'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Cuidadores'),
        ],
      ),
    );
  }
}

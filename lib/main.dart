/// lib/main.dart
///
/// v1.4 TEMPORAL — DIAGNÓSTICO. En vez de esperar todo antes de
/// runApp(), se arranca la UI inmediatamente con una pantalla que
/// ejecuta cada paso de inicialización uno por uno y muestra en
/// pantalla cuál terminó y cuál está corriendo. Si algo se cuelga,
/// vas a ver exactamente en qué paso se quedó — sin adivinar, sin
/// timeout que oculte el problema, sin necesitar adb ni Termux.
///
/// Una vez identificado el paso que falla, se revierte este archivo
/// a la versión normal y se corrige la causa real de ese paso.
library;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'services/fcm_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DiagnosticoApp());
}

class _DiagnosticoApp extends StatelessWidget {
  const _DiagnosticoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _PantallaDiagnostico(),
    );
  }
}

class _PantallaDiagnostico extends StatefulWidget {
  const _PantallaDiagnostico();

  @override
  State<_PantallaDiagnostico> createState() => _PantallaDiagnosticoState();
}

class _PantallaDiagnosticoState extends State<_PantallaDiagnostico> {
  final List<String> _pasos = [];
  bool _listo = false;
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _ejecutarPasos();
  }

  void _log(String texto) {
    setState(() => _pasos.add(texto));
  }

  Future<void> _ejecutarPasos() async {
    _log('Iniciando AlarmService...');
    await AlarmService.inicializar();
    _log('✅ AlarmService.inicializar() completo');

    _log('Reprogramando desde storage...');
    await AlarmService.reprogramarDesdeStorage();
    _log('✅ reprogramarDesdeStorage() completo');

    _log('Iniciando FCM (Firebase)...');
    await FcmService.inicializar();
    _log('✅ FcmService.inicializar() completo');

    _log('Cargando formato de fecha español...');
    await initializeDateFormatting('es');
    _log('✅ initializeDateFormatting() completo');

    _log('Revisando sesión guardada...');
    final haySesion = await StorageService.haySesionGuardada();
    _log('✅ Sesión revisada: $haySesion');

    setState(() {
      _listo = true;
      _haySesion = haySesion;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_listo) {
      return _haySesion ? const DashboardScreen() : const LoginScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diagnóstico de arranque',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _pasos.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_pasos[i], style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

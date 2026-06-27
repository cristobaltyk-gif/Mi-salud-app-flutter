/// lib/main.dart
///
/// Punto de entrada. Inicializa el servicio de alarmas ANTES de levantar
/// la UI (necesario para que el canal de Android exista desde el arranque),
/// y decide la pantalla inicial según si hay una sesión guardada.
library;

import 'package:flutter/material.dart';
import 'services/alarm_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debe inicializarse antes de runApp para que el canal de notificaciones
  // de Android exista desde el primer frame.
  await AlarmService.inicializar();

  runApp(const MiSaludApp());
}

class MiSaludApp extends StatelessWidget {
  const MiSaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiSalud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB), // azul clínico, neutro
        fontFamily: 'Roboto',
      ),
      home: const _DecidirInicio(),
    );
  }
}

/// Pantalla invisible que decide a dónde ir según si hay sesión guardada.
/// No es una "splash screen" visual con logo — solo resuelve el routing
/// inicial. Si más adelante quieres un splash con branding, se agrega
/// aquí mismo antes del FutureBuilder.
class _DecidirInicio extends StatelessWidget {
  const _DecidirInicio();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StorageService.haySesionGuardada(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final haySesion = snapshot.data ?? false;
        return haySesion ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}

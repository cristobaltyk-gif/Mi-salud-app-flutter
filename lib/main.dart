/// lib/main.dart
///
/// Punto de entrada. Inicializa el servicio de alarmas ANTES de levantar
/// la UI (necesario para que el canal de Android exista desde el arranque),
/// y decide la pantalla inicial según si hay una sesión guardada.
///
/// v1.1: FIX — se agrega initializeDateFormatting('es') antes de runApp.
/// recordatorios_screen.dart usa DateFormat(..., 'es') para mostrar
/// "Mañana a las 08:00" / nombres de día en español — el paquete intl
/// exige inicializar explícitamente los datos de un locale antes de
/// usarlo, o lanza LocaleDataException en tiempo de ejecución.
library;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debe inicializarse antes de runApp para que el canal de notificaciones
  // de Android exista desde el primer frame.
  await AlarmService.inicializar();

  // Requerido por DateFormat(..., 'es') en recordatorios_screen.dart —
  // sin esto, formatear fechas en español lanza LocaleDataException.
  await initializeDateFormatting('es');

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

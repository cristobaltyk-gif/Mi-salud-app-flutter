/// lib/main.dart
///
/// v1.3: agrega FcmService.inicializar() después de reprogramarDesdeStorage()
/// — inicializa Firebase Cloud Messaging para que las alarmas se
/// actualicen solas cuando ICA notifica un evento nuevo o cambio de
/// agenda, sin que el paciente tenga que abrir la app.
///
/// v1.2: agrega reprogramarDesdeStorage() después de inicializar() —
/// reprograma las alarmas locales desde storage sin necesitar token ni
/// conexión, para que funcionen aunque el JWT haya expirado.
library;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'services/fcm_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AlarmService.inicializar();

  // Reprograma alarmas desde storage local — no necesita token ni
  // conexión. Garantiza que las alarmas funcionen aunque el JWT
  // haya expirado o la app se haya reiniciado.
  await AlarmService.reprogramarDesdeStorage();

  await FcmService.inicializar();

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
        colorSchemeSeed: const Color(0xFF2563EB),
        fontFamily: 'Roboto',
      ),
      home: const _DecidirInicio(),
    );
  }
}

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

/// lib/main.dart
///
/// v1.8 — Arranque a prueba de fallas: antes, si cualquiera de las
/// tareas de inicio (alarmas, Firebase, formato de fechas) fallaba o se
/// quedaba esperando, runApp() nunca se ejecutaba y la app quedaba en
/// blanco. Ahora cada tarea tiene su propio try/catch y un tiempo máximo;
/// la app abre igual y el error queda en el log. Además, si una pantalla
/// falla al dibujarse, se muestra el mensaje del error en vez de una
/// pantalla vacía (ErrorWidget.builder).
///
/// v1.7 — Se agrega navigatorKey al MaterialApp (ver
/// services/navigation_service.dart), para poder navegar a
/// MediaEjercicioScreen desde AlarmService al tocar una notificación
/// de ejercicio — ese callback corre sin BuildContext disponible, así
/// que necesita el Navigator global en vez de uno local a un widget.
///
/// v1.6 — FIX: se saca RecordatoriosService.generarDesdeAgenda() de
/// main(). main() solo corre en el cold start del proceso — en ese
/// momento, si es la primera vez que se abre la app, todavía no hay
/// sesión iniciada (main() corre antes de que LoginScreen se muestre),
/// así que la llamada fallaba con "No hay sesión activa" y nunca se
/// reintentaba (main() no vuelve a correr solo por reabrir la app,
/// solo si el proceso se mata por completo). Se mueve a
/// dashboard_screen.dart, dentro de _sincronizarAlarmas(), que sí
/// corre cada vez que se entra al Dashboard con sesión ya garantizada.
///
/// v1.4: FcmService.inicializar() ahora recibe el parámetro onLog
/// (opcional, no se usa en producción — solo lo usa la pantalla de
/// diagnóstico temporal que se usó para encontrar el bug de
/// _buscar_reserva en agenda_recordatorios.py).
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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'services/fcm_service.dart';
import 'services/storage_service.dart';
import 'services/navigation_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
/// Ejecuta una tarea de inicio sin que pueda bloquear la apertura de la app.
Future<void> _pasoInicio(String nombre, Future<void> Function() tarea) async {
  try {
    await tarea().timeout(const Duration(seconds: 8));
  } on TimeoutException {
    debugPrint('[inicio] $nombre: tiempo de espera agotado, se continúa');
  } catch (e, st) {
    debugPrint('[inicio] $nombre falló: $e\n$st');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si una pantalla falla al dibujarse, mostrar el error (no una pantalla vacía)
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ocurrió un error al mostrar esta pantalla:\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ),
      );

  await _pasoInicio('formato de fechas', () => initializeDateFormatting('es'));
  await _pasoInicio('alarmas', AlarmService.inicializar);
  // Reprograma alarmas desde storage local — no necesita token ni
  // conexión. Garantiza que las alarmas funcionen aunque el JWT
  // haya expirado o la app se haya reiniciado.
  await _pasoInicio('reprogramar alarmas', AlarmService.reprogramarDesdeStorage);
  await _pasoInicio('Firebase', () => FcmService.inicializar());
  runApp(const MiSaludApp());
}
class MiSaludApp extends StatelessWidget {
  const MiSaludApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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

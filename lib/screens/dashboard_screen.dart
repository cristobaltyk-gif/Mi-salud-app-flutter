/// lib/screens/dashboard_screen.dart
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import 'ficha_screen.dart';
import 'recordatorios_screen.dart';
import 'cotizador_screen.dart';
import 'compartir_ficha_cuidado_screen.dart';
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
      // Cubre el caso de sesión ya guardada (usuario que entra directo
      // acá sin pasar por LoginScreen, ej. reabrió la app sin cerrar
      // sesión). Reintenta el registro del token FCM cada vez que se
      // entra al Dashboard con sesión garantizada — si el token ya
      // estaba registrado, el backend simplemente lo sobrescribe.
      await FcmService.registrarTokenSiHaySesion();
      await RecordatoriosService.generarDesdeAgenda();
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

  // v2 (04-08-2026): "Cuidadores" sale del tab bar (sube como boton
  // dentro de FichaScreen) y entran "Cotizador" y "Autorizar medico" en
  // su lugar. Con esto el tab bar queda IGUAL en modo propio y en modo
  // cuidador (antes el 3er tab decia "Cuidadores" en un modo y
  // "Autorizar" en el otro -- inconsistente).
  static const _tabs = [
    (icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
    (icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
    (icono: Icons.medication_outlined, iconoActivo: Icons.medication, label: 'Cotizador'),
    (icono: Icons.lock_outline, iconoActivo: Icons.lock, label: 'Autorizar'),
  ];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const FichaScreen(),
      RecordatoriosScreen(onRecordatoriosCambiaron: _sincronizarAlarmas),
      const CotizadorScreen(),
      const _AutorizarMedicoTab(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      // Mas contraste que antes (0.1 -> 0.16) para que el
                      // tab activo se distinga mejor sin cambiar el estilo.
                      color: activo ? const Color(0xFF1A3B8C).withOpacity(0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activo ? tab.iconoActivo : tab.icono,
                          // Inactivo mas oscuro que antes (grey[500] ->
                          // grey[700]) para que se lea mejor sobre fondo
                          // blanco, manteniendo la misma paleta.
                          color: activo ? const Color(0xFF1A3B8C) : Colors.grey[700],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
                              color: activo ? const Color(0xFF1A3B8C) : Colors.grey[700],
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

/// Wrapper para el tab "Autorizar" -- CompartirFichaCuidadoScreen
/// necesita el rut del paciente (antes se resolvia async justo antes de
/// navegar con Navigator.push, ver el boton original en FichaScreen).
/// Como ahora es un tab embebido (no una ruta separada), se resuelve
/// aca con FutureBuilder antes de construirla.
///
/// OJO: si CompartirFichaCuidadoScreen trae su propio Scaffold/AppBar
/// (probable, dado que antes se abria con Navigator.push como pantalla
/// completa), esto va a mostrar un AppBar duplicado dentro del Scaffold
/// del Dashboard. Si eso pasa, avisar para ajustar (lo mas probable:
/// extraer el body de esa pantalla a un widget aparte sin Scaffold
/// propio, reutilizable tanto en este tab como en cualquier otro lugar
/// donde se siga usando como ruta independiente).
class _AutorizarMedicoTab extends StatelessWidget {
  const _AutorizarMedicoTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService.obtenerRut(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rut = snapshot.data;
        if (rut == null) {
          return const Center(child: Text('No se pudo determinar tu RUT.'));
        }
        return CompartirFichaCuidadoScreen(rutPaciente: rut);
      },
    );
  }
}

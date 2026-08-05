/// lib/screens/dashboard_screen.dart
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import '../widgets/barra_inferior_tabs.dart';
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

  Future<void> _abrirAutorizarMedico() async {
    final rut = await StorageService.obtenerRut();
    if (!mounted || rut == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompartirFichaCuidadoScreen(rutPaciente: rut),
      ),
    );
  }

  // v2 (04-08-2026): "Cuidadores" sale del tab bar (sube como boton
  // dentro de FichaScreen) y entran "Cotizador" y "Autorizar medico" en
  // su lugar. "Autorizar" es un ATAJO (Navigator.push a
  // CompartirFichaCuidadoScreen, que trae su propio Scaffold/AppBar
  // completo -- confirmado revisando el archivo), no un tab embebido
  // como los otros 3 -- si se embebiera directo quedaria un Scaffold
  // anidado dentro de este. Al tocarlo no cambia _tabActual, solo abre
  // la pantalla encima (misma UX que tenia el boton original en
  // ficha_screen.dart, ahora accesible tambien desde el tab bar).
  //
  // v3 (04-08-2026): tab bar reemplazado por el widget compartido
  // BarraInferiorTabs (lib/widgets/barra_inferior_tabs.dart), usado
  // tambien en ficha_cuidado_screen.dart -- antes este mismo bloque de
  // Container+Row+GestureDetector estaba duplicado en ambos archivos.
  static const _tabs = [
    TabInfo(icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
    TabInfo(icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
    TabInfo(icono: Icons.medication_outlined, iconoActivo: Icons.medication, label: 'Cotizador'),
    TabInfo(icono: Icons.lock_outline, iconoActivo: Icons.lock, label: 'Autorizar'),
  ];

  // Solo estas 3 paginas se muestran embebidas -- el indice 3
  // ("Autorizar") nunca llega a mostrarse como pagina, ver onTap abajo.
  static const _cantidadPaginasEmbebidas = 3;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const FichaScreen(),
      RecordatoriosScreen(onRecordatoriosCambiaron: _sincronizarAlarmas),
      const CotizadorScreen(),
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
          Expanded(
            child: paginas[_tabActual < _cantidadPaginasEmbebidas ? _tabActual : 0],
          ),
        ],
      ),
      bottomNavigationBar: BarraInferiorTabs(
        tabs: _tabs,
        tabActual: _tabActual,
        color: const Color(0xFF1A3B8C),
        onTap: (i) {
          if (i == 3) {
            _abrirAutorizarMedico();
          } else {
            setState(() => _tabActual = i);
          }
        },
      ),
    );
  }
}

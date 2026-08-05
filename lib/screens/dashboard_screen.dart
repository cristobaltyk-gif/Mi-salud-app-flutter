/// lib/screens/dashboard_screen.dart
///
/// v4 (04-08-2026): rediseño grande -- selector de "carpetas" arriba
/// (Tú + una por cada persona cuidada, ver selector_carpetas.dart).
/// Los 4 tabs de abajo (Ficha, Recordatorios, Cotizador, Autorizar) se
/// quedan IGUALES en estructura, pero ahora leen datos segun la
/// carpeta activa en vez de ser siempre "los tuyos": ver
/// ficha_tab_unificada.dart, recordatorios_tab_unificada.dart,
/// cotizador_tab_unificada.dart, autorizar_tab_unificada.dart.
///
/// CuidadorScreen (invitar/gestionar cuidadores, escanear QR) ya no se
/// alcanza desde el tab bar -- es una pantalla de ADMINISTRACION, no
/// contenido de una persona en particular, asi que se movio a un
/// icono en el AppBar (junto al de cerrar sesion).
///
/// Ya no hace falta el "atajo" que evitaba el Scaffold anidado en
/// Autorizar (ver version anterior) -- AutorizarTabUnificada por
/// dentro solo muestra un boton que hace Navigator.push cuando se
/// TOCA, no cuando el tab se MUESTRA, asi que no hay conflicto de
/// Scaffold al dejarlo como tab embebido normal.
library;

import 'package:flutter/material.dart';
import '../models/carpeta_activa.dart';
import '../services/auth_service.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import '../services/fcm_service.dart';
import '../services/cuidador_service.dart';
import '../widgets/barra_inferior_tabs.dart';
import '../widgets/selector_carpetas.dart';
import 'ficha_tab_unificada.dart';
import 'recordatorios_tab_unificada.dart';
import 'cotizador_tab_unificada.dart';
import 'autorizar_tab_unificada.dart';
import 'cuidador_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabActual = 0;
  int _carpetaActual = 0;
  bool _sincronizando = true;
  String? _errorSincronizacion;

  List<CarpetaActiva> _carpetas = const [
    CarpetaActiva.propia(nombreMostrar: 'Tú'),
  ];

  @override
  void initState() {
    super.initState();
    _sincronizarAlarmas();
    _cargarCuidados();
  }

  Future<void> _cargarCuidados() async {
    try {
      final cuidados = await CuidadorService.misCuidados();
      if (!mounted) return;
      setState(() {
        _carpetas = [
          const CarpetaActiva.propia(nombreMostrar: 'Tú'),
          ...cuidados.map((c) => CarpetaActiva.cuidado(
                rutPaciente: c.rutPaciente,
                nombreMostrar: c.nombreCompleto.split(' ').first,
                nivelAcceso: c.nivelAcceso,
              )),
        ];
      });
    } catch (e) {
      // No bloqueante: si falla, el selector se queda solo con "Tú"
      // (mismo comportamiento que si el paciente no cuida a nadie).
      debugPrint('Error cargando cuidados: $e');
    }
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

  void _abrirCuidadores() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CuidadorScreen()),
    ).then((_) {
      // Al volver de administrar cuidadores, refresca el selector por
      // si invito/escaneo a alguien nuevo mientras estaba alla.
      _cargarCuidados();
    });
  }

  static const _tabs = [
    TabInfo(icono: Icons.folder_shared_outlined, iconoActivo: Icons.folder_shared, label: 'Ficha'),
    TabInfo(icono: Icons.alarm_outlined, iconoActivo: Icons.alarm, label: 'Recordatorios'),
    TabInfo(icono: Icons.medication_outlined, iconoActivo: Icons.medication, label: 'Cotizador'),
    TabInfo(icono: Icons.lock_outline, iconoActivo: Icons.lock, label: 'Autorizar'),
  ];

  @override
  Widget build(BuildContext context) {
    final carpeta = _carpetas[_carpetaActual < _carpetas.length ? _carpetaActual : 0];

    // Key por carpeta (no solo por tab) -- sin esto, Flutter reutiliza
    // el mismo State al cambiar de carpeta (misma posicion en el
    // arbol, mismo runtimeType) y el fetch en initState no se vuelve a
    // disparar. Con la key, cambiar de carpeta fuerza un widget nuevo.
    final idCarpeta = carpeta.rutPaciente ?? 'propia';

    final paginas = [
      FichaTabUnificada(key: ValueKey('ficha-$idCarpeta'), carpeta: carpeta),
      RecordatoriosTabUnificada(key: ValueKey('record-$idCarpeta'), carpeta: carpeta),
      CotizadorTabUnificada(key: ValueKey('cotiz-$idCarpeta'), carpeta: carpeta),
      AutorizarTabUnificada(key: ValueKey('autoriz-$idCarpeta'), carpeta: carpeta),
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
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            tooltip: 'Cuidadores',
            onPressed: _abrirCuidadores,
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
          SelectorCarpetas(
            carpetas: _carpetas,
            indiceActivo: _carpetaActual,
            onSeleccionar: (i) => setState(() => _carpetaActual = i),
          ),
          Expanded(child: paginas[_tabActual]),
        ],
      ),
      bottomNavigationBar: BarraInferiorTabs(
        tabs: _tabs,
        tabActual: _tabActual,
        color: const Color(0xFF1A3B8C),
        onTap: (i) => setState(() => _tabActual = i),
      ),
    );
  }
}

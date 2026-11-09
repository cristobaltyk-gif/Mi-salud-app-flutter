/// lib/screens/dashboard_screen.dart
///
/// v4.1: 5° botón "Agenda" (agendar horas nuevas, cambiar o cancelar las
/// existentes; para ti o para la persona cuidada). Las citas ya agendadas,
/// con su mapa y código, se ven en Recordatorios.
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
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/carpeta_activa.dart';
import '../services/auth_service.dart';
import '../services/biometria_service.dart';
import '../services/storage_service.dart';
import '../services/recordatorios_service.dart';
import '../services/alarm_service.dart';
import '../services/fcm_service.dart';
import '../services/cuidador_service.dart';
import '../services/contratos_service.dart';
import '../widgets/firma_terminos.dart';
import '../widgets/barra_inferior_tabs.dart';
import '../widgets/selector_carpetas.dart';
import 'ficha_tab_unificada.dart';
import 'recordatorios_tab_unificada.dart';
import 'agenda_tab_unificada.dart';
import 'cotizador_tab_unificada.dart';
import 'autorizar_tab_unificada.dart';
import 'cuidador_screen.dart';
import 'login_screen.dart';
import 'desbloquear_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await _revisarTerminos()) return;
      await _ofrecerHuellaAlEntrar();
    });
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

  // ── Ingreso con huella ────────────────────────────────────────────────
  // Al llegar al inicio por primera vez se ofrece (una sola vez). El botón 🔑
  // la activa o desactiva. Si el teléfono aún no está vinculado (p. ej. tenía
  // la sesión abierta de antes), se vincula confirmando la contraseña.
  // Si algo falla se muestra el motivo (antes fallaba en silencio).
  /// Términos de uso sin aceptar (primera vez o versión nueva): sin aceptarlos no sigue.
  /// Devuelve false si eligió salir (ya se cerró la sesión).
  Future<bool> _revisarTerminos() async {
    final doc = await ContratosService.pendiente();
    if (doc == null || !mounted) return true;
    if (await pedirFirmaTerminos(context, doc)) return true;
    await AuthService.cerrarSesionServidor();
    await AuthService.logout();
    if (!mounted) return false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return false;
  }

  Future<void> _ofrecerHuellaAlEntrar() async {
    if (await StorageService.biometriaActiva() != null) return;   // ya se le preguntó
    if (!mounted) return;
    await _activarHuella(alEntrar: true);
  }

  Future<void> _configurarHuella() async {
    final activa = await StorageService.biometriaActiva() ?? false;
    if (!mounted) return;
    if (activa) {
      final desactivar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF1A3B8C)),
          title: const Text('La huella está activa'),
          content: const Text('Entras con tu huella y te la pedimos si no usas la app por 5 minutos. '
              '¿Quieres desactivarla? Volverás a entrar con tu contraseña.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desactivar')),
          ],
        ),
      );
      if (desactivar == true) {
        await StorageService.guardarBiometria(false);
        _aviso('Huella desactivada');
      }
      return;
    }
    await _activarHuella(alEntrar: false);
  }

  Future<void> _activarHuella({required bool alEntrar}) async {
    if (!await BiometriaService.disponible()) {
      if (!alEntrar) await _mensaje('Ingreso con huella', BiometriaService.ultimoError ?? 'Este teléfono no permite huella.');
      if (alEntrar) {
        _aviso(BiometriaService.ultimoError ?? 'Este teléfono no permite huella.');
        await StorageService.guardarBiometria(false);
      }
      return;
    }
    if (!mounted) return;
    final quiere = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF1A3B8C)),
        title: const Text('¿Entrar con tu huella?'),
        content: const Text('Entra con tu huella (o el PIN de tu teléfono) sin escribir la contraseña. '
            'Si no usas la app por 5 minutos, te la pediremos para proteger tu ficha.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Activar')),
        ],
      ),
    );
    if (quiere != true) {
      if (alEntrar) await StorageService.guardarBiometria(false);   // no volver a preguntar solo
      return;
    }

    // Teléfono no vinculado: se vincula confirmando la contraseña
    if ((await StorageService.obtenerLlave() ?? '').isEmpty) {
      final password = await _pedirContrasena();
      if (password == null) return;
      try {
        await AuthService.vincularTelefono(password);
      } on AuthException catch (e) {
        await _mensaje('No se pudo activar', e.mensaje);
        return;
      } catch (_) {
        await _mensaje('No se pudo activar', 'No se pudo conectar. Revisa tu conexión e intenta de nuevo.');
        return;
      }
    }

    if (!await BiometriaService.autenticar(motivo: 'Confirma tu huella para activarla en MiSalud')) {
      await _mensaje('No se activó la huella', BiometriaService.ultimoError ?? 'No se confirmó la huella.');
      return;
    }
    await StorageService.guardarBiometria(true);
    _aviso('✓ Huella activada');
  }

  Future<String?> _pedirContrasena() async {
    final ctrl = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirma tu contraseña'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Contraseña de MiSalud'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Confirmar')),
        ],
      ),
    );
    ctrl.dispose();
    return (r == null || r.isEmpty) ? null : r;
  }

  Future<void> _mensaje(String titulo, String texto) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ),
    );
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // v2: "Salir" como un banco — el teléfono sigue de confianza, la próxima
  // vez se entra con huella y las alarmas de medicamentos siguen sonando.
  // "Olvidar este teléfono" borra todo (teléfono prestado o que se vende).
  Future<void> _cerrarSesion() async {
    final huella = await StorageService.puedeUsarHuella();
    if (!mounted) return;
    final opcion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(huella
                ? 'La próxima vez entras con tu huella. Tus recordatorios seguirán sonando.'
                : 'Tus recordatorios seguirán sonando en este teléfono.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF64748B)),
                  onPressed: () => launchUrl(Uri.parse(AppConfig.privacidadUrl), mode: LaunchMode.inAppBrowserView),
                  child: const Text('Política de privacidad', style: TextStyle(fontSize: 12.5)),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFB91C1C)),
                  onPressed: () => Navigator.pop(ctx, 'eliminar'),
                  child: const Text('Eliminar mi cuenta', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, 'olvidar'),
            child: const Text('Olvidar este teléfono'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, 'salir'), child: const Text('Salir')),
        ],
      ),
    );
    if (opcion == null) return;
    if (opcion == 'eliminar') return _eliminarCuenta();
    final olvidar = opcion == 'olvidar';
    if (olvidar) await AlarmService.cancelarTodas();
    await AuthService.cerrarSesionServidor(olvidar: olvidar);
    await AuthService.logout(olvidar: olvidar);
    final conHuella = !olvidar && await StorageService.puedeUsarHuella();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => conHuella ? const DesbloquearScreen() : const LoginScreen()),
      (route) => false,
    );
  }

  // Exigencia de Google Play: borrar la cuenta desde la app. Se borra el
  // acceso, los recordatorios y los cuidadores; la ficha clínica no (es del
  // centro y la ley obliga a conservarla). También en la web: /eliminar-cuenta
  Future<void> _eliminarCuenta() async {
    final ctrl = TextEditingController();
    var entiende = false;
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          icon: const Icon(Icons.delete_forever, size: 40, color: Color(0xFFB91C1C)),
          title: const Text('Eliminar mi cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Se borran tu acceso, tus recordatorios, tus cuidadores y las personas que cuidas.\n\n'
                    'Tu ficha clínica no se borra: la conserva tu centro de salud porque la ley lo exige. '
                    'Si vuelves a activar tu cuenta podrás verla de nuevo.'),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirma con tu contraseña'),
                  onChanged: (_) => setD(() {}),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: entiende,
                  onChanged: (v) => setD(() => entiende = v ?? false),
                  title: const Text('Entiendo que no se puede deshacer', style: TextStyle(fontSize: 13.5)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
              onPressed: entiende && ctrl.text.isNotEmpty ? () => Navigator.pop(ctx, ctrl.text) : null,
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (password == null || password.isEmpty) return;
    try {
      final mensaje = await AuthService.eliminarCuenta(password);
      await AlarmService.cancelarTodas();
      await AuthService.logout(olvidar: true);
      if (!mounted) return;
      await _mensaje('Cuenta eliminada', mensaje);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      await _mensaje('No se pudo eliminar', e.mensaje);
    } catch (_) {
      await _mensaje('No se pudo eliminar', 'No se pudo conectar. Revisa tu conexión e intenta de nuevo.');
    }
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
    TabInfo(icono: Icons.event_outlined, iconoActivo: Icons.event, label: 'Agenda'),
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
      AgendaTabUnificada(key: ValueKey('agenda-$idCarpeta'), carpeta: carpeta),
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
            icon: const Icon(Icons.fingerprint, color: Colors.white),
            tooltip: 'Ingreso con huella',
            onPressed: _configurarHuella,
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

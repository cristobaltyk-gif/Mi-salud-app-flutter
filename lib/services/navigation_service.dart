/// lib/services/navigation_service.dart
///
/// GlobalKey del Navigator raíz de la app, compartido entre main.dart
/// (que lo pasa al MaterialApp) y alarm_service.dart (que lo usa para
/// navegar al tocar una notificación, desde un callback que corre sin
/// BuildContext disponible). Vive en su propio archivo, sin lógica,
/// para que ninguno de los dos tenga que importar al otro.
library;

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

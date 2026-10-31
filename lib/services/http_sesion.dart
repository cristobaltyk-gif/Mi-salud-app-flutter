/// lib/services/http_sesion.dart — v1.0
///
/// Sesión vencida → pantalla de inicio de sesión (antes: "error" y
/// "Reintentar" para siempre, sin volver a pedir la contraseña).
///
/// 1. Reemplaza a `package:http` en los servicios: mismas funciones
///    (get, post, put, patch, delete) y además, si el backend responde
///    401 a una petición que llevaba la sesión (Authorization), la sesión
///    se da por vencida. Los servicios solo cambian su import:
///      import 'http_sesion.dart' as http;
///    El resto de package:http (Response, Client, Request…) se re-exporta.
///
/// 2. SesionVencida.cerrar(): borra el token y el RUT y lleva a la
///    pantalla de inicio de sesión con el aviso "Tu sesión expiró".
///    Los recordatorios y las alarmas de medicamentos se mantienen
///    (siguen sonando); solo "Salir" en el inicio los borra.
///
/// 3. SesionVencida.tokenVencido(token): lee la fecha de vencimiento del
///    JWT sin llamar al servidor (al abrir la app y al volver a ella).
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/login_screen.dart';
import 'navigation_service.dart';
import 'storage_service.dart';

export 'package:http/http.dart' hide get, post, put, patch, delete;

bool _conSesion(Map<String, String>? headers) =>
    headers?.keys.any((k) => k.toLowerCase() == 'authorization') ?? false;

Future<http.Response> _revisar(Future<http.Response> peticion, Map<String, String>? headers) async {
  final res = await peticion;
  if (res.statusCode == 401 && _conSesion(headers)) {
    unawaited(SesionVencida.cerrar());
  }
  return res;
}

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _revisar(http.get(url, headers: headers), headers);

Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _revisar(http.post(url, headers: headers, body: body, encoding: encoding), headers);

Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _revisar(http.put(url, headers: headers, body: body, encoding: encoding), headers);

Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _revisar(http.patch(url, headers: headers, body: body, encoding: encoding), headers);

Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _revisar(http.delete(url, headers: headers, body: body, encoding: encoding), headers);

class SesionVencida {
  static bool _cerrando = false;

  /// true si el JWT ya venció (o vence en menos de 30 s) o no se puede leer.
  static bool tokenVencido(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final partes = token.split('.');
      if (partes.length != 3) return true;
      final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
      final exp = (datos as Map<String, dynamic>)['exp'];
      if (exp is! num) return false; // sin vencimiento: lo decide el servidor
      final vence = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(vence.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  /// Momento en que vence el token guardado (null si no hay o no se puede leer).
  static Future<DateTime?> venceEl() async {
    final token = await StorageService.obtenerToken();
    if (token == null || token.isEmpty) return null;
    try {
      final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
      final exp = (datos as Map<String, dynamic>)['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  /// Si hay sesión guardada y ya venció, la cierra. Devuelve true si la cerró.
  static Future<bool> revisar() async {
    final token = await StorageService.obtenerToken();
    if (token == null || token.isEmpty) return false;
    if (!tokenVencido(token)) return false;
    await cerrar();
    return true;
  }

  /// Borra la sesión (no los recordatorios) y vuelve al inicio de sesión.
  static Future<void> cerrar() async {
    if (_cerrando) return;
    _cerrando = true;
    try {
      await StorageService.cerrarSesionVencida();
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(aviso: 'Tu sesión expiró. Vuelve a ingresar con tu contraseña.'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[sesión] no se pudo cerrar la sesión vencida: $e');
    } finally {
      _cerrando = false;
    }
  }
}

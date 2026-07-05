/// lib/services/credenciales_service.dart
/// Gestiona descargas y almacenamiento encriptado de credenciales

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/credencial_model.dart';
import 'storage_service.dart';

class CredencialesService {
  static const String _baseUrl = 'https://misalud-backend.onrender.com';
  static const String _storageKey = 'credenciales_wallet';

  /// Descarga credenciales desde backend
  static Future<List<CredencialVerificable>> descargarCredenciales(String rut, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/credenciales/$rut'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final credencialesList = (data['credenciales'] as List?)
            ?.map((c) => CredencialVerificable.fromJson(c))
            .toList() ?? [];
        
        // Guardar localmente
        await guardarCredencialesLocalmente(credencialesList);
        return credencialesList;
      } else {
        throw Exception('Error descargando credenciales: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en descargarCredenciales: $e');
      rethrow;
    }
  }

  /// Descargar credenciales por tipo
  static Future<List<CredencialVerificable>> descargarPorTipo(
    String rut,
    String tipo,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/credenciales/$rut/$tipo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['credenciales'] as List?)
            ?.map((c) => CredencialVerificable.fromJson(c))
            .toList() ?? [];
      } else {
        throw Exception('Error descargando credenciales por tipo');
      }
    } catch (e) {
      print('Error en descargarPorTipo: $e');
      rethrow;
    }
  }

  /// Guardar credenciales en almacenamiento local (encriptado)
  static Future<void> guardarCredencialesLocalmente(
    List<CredencialVerificable> credenciales,
  ) async {
    try {
      final json = jsonEncode(
        credenciales.map((c) => c.toJson()).toList(),
      );
      // StorageService maneja encriptación automáticamente
      await StorageService.guardar(_storageKey, json);
    } catch (e) {
      print('Error guardando credenciales localmente: $e');
      rethrow;
    }
  }

  /// Cargar credenciales desde almacenamiento local
  static Future<List<CredencialVerificable>> cargarCredencialesLocalmente() async {
    try {
      final json = await StorageService.obtener(_storageKey);
      if (json == null || json.isEmpty) {
        return [];
      }
      final lista = jsonDecode(json) as List;
      return lista
          .map((c) => CredencialVerificable.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error cargando credenciales localmente: $e');
      return [];
    }
  }

  /// Sincronizar: descargar + guardar
  static Future<List<CredencialVerificable>> sincronizar(
    String rut,
    String token,
  ) async {
    try {
      final credenciales = await descargarCredenciales(rut, token);
      return credenciales;
    } catch (e) {
      print('Error sincronizando: $e');
      // Fallback: retornar locales si falla descarga
      return cargarCredencialesLocalmente();
    }
  }

  /// Eliminar credencial local
  static Future<void> eliminarLocal(String credencialId) async {
    try {
      final credenciales = await cargarCredencialesLocalmente();
      credenciales.removeWhere((c) => c.id == credencialId);
      await guardarCredencialesLocalmente(credenciales);
    } catch (e) {
      print('Error eliminando credencial: $e');
      rethrow;
    }
  }

  /// Limpiar todas las credenciales
  static Future<void> limpiarTodas() async {
    try {
      await StorageService.eliminar(_storageKey);
    } catch (e) {
      print('Error limpiando credenciales: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas
  static Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final credenciales = await cargarCredencialesLocalmente();
      final stats = <String, int>{};
      
      for (var c in credenciales) {
        stats[c.tipo] = (stats[c.tipo] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {};
    }
  }
}

/// lib/screens/credenciales_screen.dart
/// Pantalla de billetera: muestra credenciales del paciente

import 'package:flutter/material.dart';
import '../models/credencial_model.dart';
import '../services/credenciales_service.dart';
import '../services/storage_service.dart';

class CredencialesScreen extends StatefulWidget {
  const CredencialesScreen({super.key});

  @override
  State<CredencialesScreen> createState() => _CredencialesScreenState();
}

class _CredencialesScreenState extends State<CredencialesScreen> {
  late Future<List<CredencialVerificable>> _credenciales;
  String _filtroTipo = 'todas';

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  void _cargarCredenciales() {
    setState(() {
      _credenciales = CredencialesService.cargarCredencialesLocalmente();
    });
  }

  Future<void> _sincronizar() async {
    try {
      final rut = await StorageService.obtener('rut_paciente') ?? '';
      final token = await StorageService.obtener('jwt_token') ?? '';

      if (rut.isEmpty || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión expirada')),
          );
        }
        return;
      }

      setState(() {
        _credenciales = CredencialesService.sincronizar(rut, token);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Credenciales sincronizadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Credenciales'),
        backgroundColor: const Color(0xFF1A3B8C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _sincronizar,
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: FutureBuilder<List<CredencialVerificable>>(
        future: _credenciales,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarCredenciales,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final todas = snapshot.data ?? [];
          final filtradas = _filtroTipo == 'todas'
              ? todas
              : todas.where((c) => c.tipo == _filtroTipo).toList();

          if (todas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_membership, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No tienes credenciales aún'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sincronizar,
                    child: const Text('Sincronizar desde clínica'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('todas', 'Todas'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('diagnostico', 'Diagnósticos'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('medicamento', 'Medicamentos'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('alergia', 'Alergias'),
                    ],
                  ),
                ),
              ),
              // Lista
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final cred = filtradas[index];
                    return _buildCredencialCard(cred);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filtroTipo == valor,
      onSelected: (selected) {
        setState(() {
          _filtroTipo = valor;
        });
      },
      selectedColor: const Color(0xFF1A3B8C),
      labelStyle: TextStyle(
        color: _filtroTipo == valor ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildCredencialCard(CredencialVerificable cred) {
    final iconMap = {
      'diagnostico': Icons.healing,
      'medicamento': Icons.local_pharmacy,
      'alergia': Icons.warning,
    };

    final colorMap = {
      'diagnostico': const Color(0xFF3B82C4),
      'medicamento': const Color(0xFF1E9E6B),
      'alergia': const Color(0xFFE0A100),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          iconMap[cred.tipo] ?? Icons.card_membership,
          color: colorMap[cred.tipo] ?? Colors.grey,
        ),
        title: Text(cred.tipoDisplay),
        subtitle: Text(
          cred.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: cred.esValida
            ? const Icon(Icons.verified, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        onTap: () => _mostrarDetalle(cred),
      ),
    );
  }

  void _mostrarDetalle(CredencialVerificable cred) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cred.tipoDisplay,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetalleFila('Descripción', cred.descripcion),
            _buildDetalleFila('Emitida', cred.emitida.toString().split('.')[0]),
            if (cred.expira != null)
              _buildDetalleFila('Expira', cred.expira.toString().split('.')[0]),
            _buildDetalleFila('Estado', cred.esValida ? '✅ Válida' : '❌ Expirada'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Compartir credencial
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await CredencialesService.eliminarLocal(cred.id);
                    _cargarCredenciales();
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

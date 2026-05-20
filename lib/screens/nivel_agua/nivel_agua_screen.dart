import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class NivelAguaScreen extends StatefulWidget {
  const NivelAguaScreen({super.key});
  @override
  State<NivelAguaScreen> createState() => _NivelAguaScreenState();
}

class _NivelAguaScreenState extends State<NivelAguaScreen> {
  List<dynamic> _registros = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.get('/niveles');
      setState(() { _registros = (data as List).reversed.toList(); });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Color _color(dynamic p) {
    final v = double.tryParse(p.toString()) ?? 100;
    if (v <= 20) return AppTheme.error;
    if (v <= 40) return AppTheme.advertencia;
    return AppTheme.exito;
  }

  String _etiqueta(dynamic p) {
    final v = double.tryParse(p.toString()) ?? 100;
    if (v <= 20) return 'CRÍTICO';
    if (v <= 40) return 'ALERTA';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nivel de Agua'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                ]))
              : _registros.isEmpty
                  ? const Center(child: Text('Sin registros de nivel'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView(children: [
                        if (_registros.isNotEmpty) _cardUltimo(_registros.first),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ..._registros.map(_itemHistorial),
                      ]),
                    ),
    );
  }

  Widget _cardUltimo(Map<String, dynamic> r) {
    final p = double.tryParse(r['nivel_porcentaje'].toString()) ?? 0;
    final color = _color(p);
    return Card(
      margin: const EdgeInsets.all(16),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Icon(Icons.water_drop, color: color, size: 48),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nivel Actual', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('${p.toStringAsFixed(1)}%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
              Text('${r['nivel_litros']} litros', style: const TextStyle(fontSize: 16)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(_etiqueta(p), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: p / 100, backgroundColor: Colors.grey.shade200, color: color, minHeight: 12),
          const SizedBox(height: 8),
          if (r['observaciones'] != null && r['observaciones'].toString().isNotEmpty)
            Text('Obs: ${r['observaciones']}', style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _itemHistorial(dynamic r) {
    final p = double.tryParse(r['nivel_porcentaje'].toString()) ?? 0;
    final color = _color(p);
    final fecha = r['fecha_registro']?.toString().substring(0, 16) ?? '';
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.water_drop, color: color)),
      title: Text('${p.toStringAsFixed(1)}% — ${r['nivel_litros']} L'),
      subtitle: Text(fecha),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(_etiqueta(p), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

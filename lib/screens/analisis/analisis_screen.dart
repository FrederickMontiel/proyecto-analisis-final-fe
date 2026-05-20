import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AnalisisConsumoScreen extends StatefulWidget {
  const AnalisisConsumoScreen({super.key});
  @override
  State<AnalisisConsumoScreen> createState() => _AnalisisConsumoScreenState();
}

class _AnalisisConsumoScreenState extends State<AnalisisConsumoScreen> {
  List<dynamic> _lecturas = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/lecturas');
      setState(() { _lecturas = data as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  String _nivelConsumo(double c) {
    if (c < 10) return 'Bajo';
    if (c <= 25) return 'Normal';
    if (c <= 40) return 'Alto';
    return 'Crítico';
  }

  Color _colorNivel(double c) {
    if (c < 10) return Colors.blue;
    if (c <= 25) return AppTheme.exito;
    if (c <= 40) return AppTheme.advertencia;
    return AppTheme.error;
  }

  Map<int, List<double>> _consumosPorHogar() {
    final mapa = <int, List<double>>{};
    for (final l in _lecturas) {
      final id = l['id_hogar'] as int? ?? 0;
      final c = double.tryParse(l['consumo_calculado'].toString()) ?? 0;
      mapa.putIfAbsent(id, () => []).add(c);
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final consumos = _consumosPorHogar();
    final hogares = consumos.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de Consumo'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _lecturas.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No hay lecturas para analizar'),
                ]))
              : Column(children: [
                  _resumen(consumos),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(children: [
                      Text('Por Hogar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: hogares.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final id = hogares[i];
                        final lista = consumos[id]!;
                        final ultimo = lista.last;
                        final promedio = lista.reduce((a, b) => a + b) / lista.length;
                        final color = _colorNivel(ultimo);
                        final nivel = _nivelConsumo(ultimo);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Text('H$id', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Row(children: [
                            Text('Hogar #$id', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(nivel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          subtitle: Text('Último: ${ultimo.toStringAsFixed(1)} m³ | Promedio: ${promedio.toStringAsFixed(1)} m³ | ${lista.length} lecturas'),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${ultimo.toStringAsFixed(0)} m³',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                          ]),
                        );
                      },
                    ),
                  ),
                ]),
    );
  }

  Widget _resumen(Map<int, List<double>> consumos) {
    if (consumos.isEmpty) return const SizedBox();
    int altos = 0, criticos = 0, normales = 0, bajos = 0;
    for (final lista in consumos.values) {
      final u = lista.last;
      if (u > 40) criticos++;
      else if (u > 25) altos++;
      else if (u >= 10) normales++;
      else bajos++;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _chipResumen('Crítico', criticos, AppTheme.error),
        _chipResumen('Alto', altos, AppTheme.advertencia),
        _chipResumen('Normal', normales, AppTheme.exito),
        _chipResumen('Bajo', bajos, Colors.blue),
      ]),
    );
  }

  Widget _chipResumen(String label, int count, Color color) {
    return Column(children: [
      CircleAvatar(backgroundColor: color.withValues(alpha: 0.15),
          radius: 22, child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}

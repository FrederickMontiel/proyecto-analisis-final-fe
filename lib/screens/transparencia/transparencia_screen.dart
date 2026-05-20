import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class TransparenciaScreen extends StatefulWidget {
  const TransparenciaScreen({super.key});
  @override
  State<TransparenciaScreen> createState() => _TransparenciaScreenState();
}

class _TransparenciaScreenState extends State<TransparenciaScreen> {
  List<dynamic> _pagos = [];
  List<dynamic> _gastos = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final p = await ApiService.get('/pagos');
      final g = await ApiService.get('/gastos');
      setState(() { _pagos = p as List; _gastos = g as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  double get _totalIngresos => _pagos.fold(0, (s, p) => s + (double.tryParse(p['monto'].toString()) ?? 0));
  double get _totalGastos => _gastos.fold(0, (s, g) => s + (double.tryParse(g['monto'].toString()) ?? 0));
  double get _balance => _totalIngresos - _totalGastos;

  Map<String, double> get _gastosPorCategoria {
    final m = <String, double>{};
    for (final g in _gastos) {
      final cat = g['categoria']?.toString() ?? 'Otro';
      m[cat] = (m[cat] ?? 0) + (double.tryParse(g['monto'].toString()) ?? 0);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final superavit = _balance >= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Transparencia Financiera'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance general
                  Card(
                    color: superavit ? AppTheme.exito.withValues(alpha: 0.08) : AppTheme.error.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: superavit ? AppTheme.exito : AppTheme.error, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text(superavit ? 'SUPERÁVIT' : 'DÉFICIT',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: superavit ? AppTheme.exito : AppTheme.error, letterSpacing: 2)),
                        Text('Q. ${_balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                                color: superavit ? AppTheme.exito : AppTheme.error)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _miniCard('Ingresos', _totalIngresos, AppTheme.exito, Icons.arrow_downward)),
                          const SizedBox(width: 12),
                          Expanded(child: _miniCard('Gastos', _totalGastos, AppTheme.error, Icons.arrow_upward)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Gastos por categoría
                  const Text('Gastos por Categoría',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._gastosPorCategoria.entries.map((e) {
                    final pct = _totalGastos > 0 ? (e.value / _totalGastos) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('Q. ${e.value.toStringAsFixed(2)}'),
                          Text('  ${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.orange,
                          minHeight: 8,
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: 20),
                  // Últimos pagos
                  const Text('Últimos Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(_pagos.reversed.take(5).toList()).map((p) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.payment, color: AppTheme.exito),
                    title: Text('Q. ${double.tryParse(p['monto'].toString())?.toStringAsFixed(2)} — ${p['metodo_pago']}'),
                    subtitle: Text('Período: ${p['periodo_aplicado']}'),
                  )),
                  const SizedBox(height: 20),
                  // Últimos gastos
                  const Text('Últimos Gastos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(_gastos.reversed.take(5).toList()).map((g) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.receipt, color: Colors.orange),
                    title: Text(g['descripcion']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('Q. ${double.tryParse(g['monto'].toString())?.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ],
              ),
            ),
    );
  }

  Widget _miniCard(String titulo, double monto, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(color: color, fontSize: 12)),
          Text('Q. ${monto.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ])),
      ]),
    );
  }
}

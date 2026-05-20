import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});
  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  List<dynamic> _gastos = [];
  bool _cargando = true;
  double _total = 0;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/gastos');
      final lista = (data as List).reversed.toList();
      double t = 0;
      for (final g in lista) {
        t += double.tryParse(g['monto'].toString()) ?? 0;
      }
      setState(() { _gastos = lista; _total = t; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorCategoria(String cat) {
    switch (cat) {
      case 'Mantenimiento': return Colors.blue;
      case 'Reparación': return Colors.orange;
      case 'Energía': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Gasto'),
        backgroundColor: Colors.orange,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total de gastos', style: TextStyle(color: Colors.grey)),
                    Text('Q. ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ]),
                ]),
              ),
              Expanded(
                child: _gastos.isEmpty
                    ? const Center(child: Text('No hay gastos registrados'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _gastos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final g = _gastos[i];
                            final cat = g['categoria']?.toString() ?? '';
                            final color = _colorCategoria(cat);
                            final fecha = g['fecha_gasto']?.toString().substring(0, 10) ?? '';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(Icons.receipt, color: color),
                              ),
                              title: Text(g['descripcion']?.toString() ?? '',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('$cat | $fecha'),
                              trailing: Text('Q. ${double.tryParse(g['monto'].toString())?.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            );
                          },
                        ),
                      ),
              ),
            ]),
    );
  }

  void _mostrarFormulario() {
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    String categoria = 'Mantenimiento';
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(builder: (ctx2, setSt) => Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Registrar Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (Q)', prefixText: 'Q. ', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categoria,
              items: ['Mantenimiento', 'Reparación', 'Energía', 'Otro']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setSt(() { categoria = v!; }),
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fechaCtrl,
              decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()),
              onTap: () async {
                final d = await showDatePicker(context: ctx2,
                    initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                if (d != null) fechaCtrl.text = d.toIso8601String().substring(0, 10);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 52)),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ApiService.post('/gastos', {
                      'descripcion': descCtrl.text,
                      'monto': double.parse(montoCtrl.text),
                      'fecha_gasto': fechaCtrl.text,
                      'categoria': categoria,
                      'id_usuario_registro': AuthService.usuario!.idUsuario,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gasto registrado'), backgroundColor: AppTheme.exito));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: const Text('Guardar', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

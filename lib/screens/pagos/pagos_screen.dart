import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});
  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<dynamic> _pagos = [];
  List<dynamic> _hogares = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final p = await ApiService.get('/pagos');
      final h = await ApiService.get('/usuarios');
      setState(() {
        _pagos = (p as List).reversed.toList();
        _hogares = h as List;
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Pago'),
        backgroundColor: AppTheme.exito,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pagos.isEmpty
              ? const Center(child: Text('No hay pagos registrados'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pagos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _pagos[i];
                      final fecha = p['fecha_pago']?.toString().substring(0, 10) ?? '';
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.payment, color: AppTheme.exito),
                        ),
                        title: Text('Q. ${p['monto']} — ${p['metodo_pago']}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Período: ${p['periodo_aplicado']} | $fecha'),
                        trailing: p['numero_recibo'] != null
                            ? Text(p['numero_recibo'].toString(),
                                style: const TextStyle(fontSize: 12, color: Colors.grey))
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  void _mostrarFormulario() {
    final montoCtrl = TextEditingController();
    final periodoCtrl = TextEditingController(
        text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
    final obsCtrl = TextEditingController();
    String metodo = 'Efectivo';
    int? idHogar;
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
            const Text('Registrar Pago', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (Q)', prefixText: 'Q. ', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingrese monto';
                if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: periodoCtrl,
              decoration: const InputDecoration(labelText: 'Período (YYYY-MM)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: metodo,
              items: ['Efectivo', 'Transferencia', 'Depósito', 'Otro']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setSt(() { metodo = v!; }),
              decoration: const InputDecoration(labelText: 'Método de pago', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar Pago', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.exito, minimumSize: const Size(double.infinity, 52)),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final numero = 'PAGO-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                    await ApiService.post('/pagos', {
                      'monto': double.parse(montoCtrl.text),
                      'metodo_pago': metodo,
                      'periodo_aplicado': periodoCtrl.text,
                      'numero_recibo': numero,
                      'observaciones': obsCtrl.text,
                      'fecha_pago': DateTime.now().toIso8601String().substring(0, 10),
                      'id_usuario_registro': AuthService.usuario!.idUsuario,
                      'id_hogar': 1,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pago registrado: $numero'), backgroundColor: AppTheme.exito));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class PagosScreen extends StatefulWidget {
  final Map<String, dynamic>? hogar;
  const PagosScreen({super.key, this.hogar});
  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<dynamic> _pagos = [];
  List<dynamic> _hogares = [];
  List<dynamic> _morosos = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final p = await ApiService.get('/pagos');
      final u = await ApiService.get('/usuarios');
      final m = await ApiService.get('/morosos');
      setState(() {
        _pagos = (p as List).reversed.toList();
        _hogares = (u as List).where((u) => u['rol'] == 'Habitante').map((u) {
          u['id_hogar'] = u['id_usuario'];
          return u;
        }).toList();
        _morosos = m as List;
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Map<String, dynamic>? _obtenerMoroso(int idHogar) {
    return _morosos.firstWhere((m) => m['id_hogar'] == idHogar, orElse: () => null);
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
    int? idHogar = widget.hogar?['id_hogar'] as int?;
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
            if (widget.hogar == null)
              GestureDetector(
                onTap: _hogares.isEmpty
                    ? null
                    : () async {
                        final h = await showDialog<int>(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            title: const Text('Seleccionar Hogar'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 300,
                              child: ListView(
                                children: _hogares
                                    .where((h) => h['id_hogar'] != null)
                                    .map((h) => ListTile(
                                      title: Text(h['nombre'] ?? 'Sin nombre'),
                                      subtitle: Text(h['correo'] ?? 'N/A'),
                                      onTap: () => Navigator.pop(ctx, h['id_hogar'] as int),
                                    ))
                                    .toList(),
                              ),
                            ),
                          ),
                        );
                        if (h != null) setSt(() { idHogar = h; });
                      },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Hogar',
                    border: const OutlineInputBorder(),
                    errorText: idHogar == null ? 'Seleccione un hogar' : null,
                  ),
                  child: Text(
                    _hogares.isEmpty
                        ? 'Cargando...'
                        : _hogares.firstWhere((h) => h['id_hogar'] == idHogar, orElse: () => {})['nombre'] ?? 'Seleccionar hogar',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            if (widget.hogar == null && idHogar != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Builder(builder: (_) {
                  final moroso = _obtenerMoroso(idHogar!);
                  if (moroso == null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        const Text('Hogar al día', style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                      ]),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(color: const Color(0xFFEF5350)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.warning, color: Color(0xFFC62828), size: 18),
                        const SizedBox(width: 8),
                        Text('${moroso['meses']} meses en mora',
                          style: const TextStyle(fontSize: 13, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      Text('Deuda: Q ${(moroso['deuda'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                    ]),
                  );
                }),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.info, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Pago para: ${widget.hogar?['nombre'] ?? 'Hogar'} (${widget.hogar?['numero'] ?? '#N/A'})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  )),
                ]),
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
                  if (idHogar == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Seleccione un hogar'), backgroundColor: AppTheme.error));
                    return;
                  }
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
                      'id_hogar': idHogar,
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

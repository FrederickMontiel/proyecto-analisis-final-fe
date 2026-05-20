import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class LecturasScreen extends StatefulWidget {
  const LecturasScreen({super.key});
  @override
  State<LecturasScreen> createState() => _LecturasScreenState();
}

class _LecturasScreenState extends State<LecturasScreen> {
  List<dynamic> _lecturas = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/lecturas');
      setState(() { _lecturas = (data as List).reversed.toList(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorConsumo(dynamic consumo) {
    final v = double.tryParse(consumo.toString()) ?? 0;
    if (v > 40) return AppTheme.error;
    if (v > 25) return AppTheme.advertencia;
    return AppTheme.exito;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturas de Contadores'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.speed),
        label: const Text('Nueva Lectura'),
        backgroundColor: Colors.green,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _lecturas.isEmpty
              ? const Center(child: Text('No hay lecturas registradas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _lecturas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = _lecturas[i];
                      final consumo = double.tryParse(l['consumo_calculado'].toString()) ?? 0;
                      final color = _colorConsumo(consumo);
                      final fecha = l['fecha_lectura']?.toString().substring(0, 10) ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.speed, color: color),
                        ),
                        title: Text('Hogar #${l['id_hogar']} — ${consumo.toStringAsFixed(1)} m³',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Actual: ${l['lectura_actual']} | Anterior: ${l['lectura_anterior']} | $fecha'),
                        trailing: consumo > 25
                            ? const Icon(Icons.warning, color: AppTheme.advertencia)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  void _mostrarFormulario() {
    final actualCtrl = TextEditingController();
    final anteriorCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    String estadoContador = 'Normal';
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
            const Text('Registrar Lectura', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: anteriorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lectura anterior (m³)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: actualCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lectura actual (m³)', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final a = double.tryParse(v) ?? 0;
                    final ant = double.tryParse(anteriorCtrl.text) ?? 0;
                    if (a < ant) return 'Debe ser ≥ anterior';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: estadoContador,
              items: ['Normal', 'Dañado', 'Requiere Mantenimiento', 'No Accesible']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setSt(() { estadoContador = v!; }),
              decoration: const InputDecoration(labelText: 'Estado del contador', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 52)),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final ant = double.parse(anteriorCtrl.text);
                  final act = double.parse(actualCtrl.text);
                  final consumo = act - ant;
                  if (consumo > 30 && ctx.mounted) {
                    final ok = await showDialog<bool>(context: ctx2, builder: (_) => AlertDialog(
                      title: const Text('Consumo alto'),
                      content: Text('Consumo de ${consumo.toStringAsFixed(1)} m³. Verifique posibles fugas. ¿Confirmar?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
                      ],
                    ));
                    if (ok != true) return;
                  }
                  try {
                    await ApiService.post('/lecturas', {
                      'id_hogar': 1,
                      'lectura_anterior': ant,
                      'lectura_actual': act,
                      'consumo_calculado': consumo,
                      'fecha_lectura': DateTime.now().toIso8601String(),
                      'estado_contador': estadoContador,
                      'observaciones': obsCtrl.text,
                      'origen_lectura': 'Manual',
                      'id_usuario_lector': AuthService.usuario!.idUsuario,
                      'unidad_medida': 'Metros Cúbicos',
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lectura guardada. Consumo: ${consumo.toStringAsFixed(1)} m³'),
                          backgroundColor: consumo > 25 ? AppTheme.advertencia : AppTheme.exito));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: const Text('Guardar Lectura', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

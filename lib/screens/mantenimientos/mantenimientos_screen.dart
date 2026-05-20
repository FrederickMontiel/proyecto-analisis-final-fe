import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class MantenimientosScreen extends StatefulWidget {
  const MantenimientosScreen({super.key});
  @override
  State<MantenimientosScreen> createState() => _MantenimientosScreenState();
}

class _MantenimientosScreenState extends State<MantenimientosScreen> {
  List<dynamic> _mantenimientos = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/mantenimientos');
      setState(() { _mantenimientos = (data as List).reversed.toList(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Preventivo': return AppTheme.exito;
      case 'Correctivo': return AppTheme.advertencia;
      default: return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mantenimientos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6F42C1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Registro'),
        backgroundColor: const Color(0xFF6F42C1),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6F42C1), Color(0xFF520DC2)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(children: [
                  const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                      child: Icon(Icons.build, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AuthService.usuario?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Registro de Mantenimiento', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),
              Expanded(
                child: _mantenimientos.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView(children: [
                          const SizedBox(height: 60),
                          const Center(child: Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey)),
                          const Center(child: Text('Sin mantenimientos registrados', style: TextStyle(color: Colors.grey))),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _mantenimientos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _cardMantenimiento(_mantenimientos[i]),
                        ),
                      ),
              ),
            ]),
    );
  }

  Widget _cardMantenimiento(Map<String, dynamic> m) {
    final tipo = m['tipo_mantenimiento']?.toString() ?? '';
    final color = _colorTipo(tipo);
    final fecha = m['fecha_realizacion']?.toString().substring(0, 10) ?? '';
    final costo = double.tryParse(m['costo']?.toString() ?? '0') ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(tipo, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Text(m['descripcion']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
        if (costo > 0) ...[
          const SizedBox(height: 4),
          Text('Costo: Q ${costo.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  void _mostrarFormulario() {
    final descCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final horaInicioCtrl = TextEditingController(text: '08:00');
    final horaFinCtrl = TextEditingController();
    final materialesCtrl = TextEditingController();
    String tipo = 'Preventivo';
    String componente = 'Tanques';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, scrollCtrl) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx2, setSt) => Form(
            key: formKey,
            child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
              // Header del form
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF6F42C1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.build, color: Color(0xFF6F42C1), size: 20),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AuthService.usuario?.nombre ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Nuevo Registro', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('Tipo de Mantenimiento *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: tipo,
                items: ['Preventivo', 'Correctivo', 'Emergencia']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setSt(() { tipo = v!; }),
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Seleccione...'),
              ),
              const SizedBox(height: 14),
              const Text('Equipo/Componente *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: componente,
                items: ['Tanques', 'Bomba', 'Válvulas', 'Tuberías S1-S5', 'Medidor', 'Sistema Eléctrico']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSt(() { componente = v!; }),
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Seleccione...'),
              ),
              const SizedBox(height: 14),
              const Text('Fecha del Mantenimiento *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: fechaCtrl,
                readOnly: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2, initialDate: DateTime.now(),
                    firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) fechaCtrl.text = d.toIso8601String().substring(0, 10);
                },
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Hora de Inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(controller: horaInicioCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder())),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Hora de Finalización', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(controller: horaFinCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder())),
                ])),
              ]),
              const SizedBox(height: 14),
              const Text('Descripción del Trabajo Realizado *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Detalle las actividades realizadas, problemas encontrados y reparaciones efectuadas...',
                ),
                validator: (v) => (v?.length ?? 0) < 10 ? 'Mínimo 10 caracteres' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: materialesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Materiales/Repuestos utilizados', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: costoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Costo estimado (Q)', prefixText: 'Q ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Guardar Registro', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F42C1), minimumSize: const Size(double.infinity, 52)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ApiService.post('/mantenimientos', {
                        'tipo_mantenimiento': tipo,
                        'descripcion': '[$componente] ${descCtrl.text}',
                        'fecha_realizacion': fechaCtrl.text,
                        'costo': double.tryParse(costoCtrl.text) ?? 0,
                        'observaciones': materialesCtrl.text,
                        'id_usuario': AuthService.usuario!.idUsuario,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _cargar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Mantenimiento registrado'), backgroundColor: AppTheme.exito));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ]),
          )),
        ),
      ),
    );
  }
}

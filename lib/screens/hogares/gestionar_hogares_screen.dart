import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class GestionarHogaresScreen extends StatefulWidget {
  const GestionarHogaresScreen({super.key});
  @override
  State<GestionarHogaresScreen> createState() => _GestionarHogaresScreenState();
}

class _GestionarHogaresScreenState extends State<GestionarHogaresScreen> {
  List<dynamic> _hogares = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/hogares') ?? [];
      setState(() { _hogares = data as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Gestionar Hogares', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D6EFD),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _mostrarFormulario,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.home, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_hogares.length} Hogares Registrados',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_hogares.fold(0, (s, h) => s + (int.tryParse(h['numero_habitantes'].toString()) ?? 0))} Habitantes (est.)',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  child: _hogares.isEmpty
                      ? const Center(child: Text('No hay hogares registrados'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _hogares.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _cardHogar(_hogares[i]),
                        ),
                ),
              ),
            ]),
    );
  }

  Widget _cardHogar(Map<String, dynamic> h) {
    final habitantes = int.tryParse(h['numero_habitantes'].toString()) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: const Color(0xFF0D6EFD).withValues(alpha: 0.12), radius: 20,
              child: const Icon(Icons.home, color: Color(0xFF0D6EFD))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h['numero_hogar']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (h['responsable'] != null && h['responsable'].toString().isNotEmpty)
              Text(h['responsable'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFD1E7DD), borderRadius: BorderRadius.circular(12)),
            child: Text(h['estado']?.toString() ?? 'Activo', style: const TextStyle(color: Color(0xFF198754), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 20),
        Row(children: [
          _statChip(Icons.people, '$habitantes Habitantes', const Color(0xFF0D6EFD)),
          const SizedBox(width: 8),
          _statChip(Icons.phone, h['telefono_contacto']?.toString() ?? 'N/A', const Color(0xFF0D6EFD)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _mostrarEditar(h),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D6EFD),
                side: const BorderSide(color: Color(0xFF0D6EFD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _eliminar(h['id_hogar']),
              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
              label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _statChip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _mostrarFormulario() async {
    final sectores = await _cargarSectores();
    if (!mounted) return;

    final numeroCtrl = TextEditingController();
    final responsableCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final habitantesCtrl = TextEditingController(text: '1');
    int? idSectorSeleccionado;
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: const Text('Nuevo Hogar'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                value: idSectorSeleccionado,
                items: sectores.map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(value: s['id_sector'] as int, child: Text(s['nombre_sector'] ?? 'N/A'))).toList(),
                onChanged: (v) => setSt(() { idSectorSeleccionado = v; }),
                decoration: const InputDecoration(labelText: 'Sector *', border: OutlineInputBorder()),
                validator: (v) => v == null ? 'Seleccione sector' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: numeroCtrl,
                decoration: const InputDecoration(labelText: 'Número del Hogar *', border: OutlineInputBorder(), hintText: 'Ej: H-001'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: responsableCtrl,
                decoration: const InputDecoration(labelText: 'Responsable', border: OutlineInputBorder(), hintText: 'Nombre del responsable'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección *', border: OutlineInputBorder(), hintText: 'Dirección completa'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), hintText: 'Teléfono de contacto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: habitantesCtrl,
                decoration: const InputDecoration(labelText: 'Habitantes *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.exito),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ApiService.post('/hogares', {
                    'numero_hogar': numeroCtrl.text,
                    'responsable': responsableCtrl.text,
                    'direccion': direccionCtrl.text,
                    'telefono_contacto': telefonoCtrl.text,
                    'numero_habitantes': int.parse(habitantesCtrl.text),
                    'id_sector': idSectorSeleccionado,
                    'estado': 'Activo',
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _cargar();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Hogar creado'), backgroundColor: AppTheme.exito));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: const Text('Crear Hogar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _cargarSectores() async {
    try {
      return await ApiService.get('/sectores') ?? [];
    } catch (_) {
      return [];
    }
  }

  void _mostrarEditar(Map<String, dynamic> h) {
    final numeroCtrl = TextEditingController(text: h['numero_hogar']?.toString());
    final responsableCtrl = TextEditingController(text: h['responsable']?.toString());
    final direccionCtrl = TextEditingController(text: h['direccion']?.toString());
    final telefonoCtrl = TextEditingController(text: h['telefono_contacto']?.toString());
    final habitantesCtrl = TextEditingController(text: h['numero_habitantes']?.toString() ?? '1');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Hogar'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: numeroCtrl,
              decoration: const InputDecoration(labelText: 'Número del Hogar *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: responsableCtrl,
              decoration: const InputDecoration(labelText: 'Responsable', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: telefonoCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: habitantesCtrl,
              decoration: const InputDecoration(labelText: 'Habitantes *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.put('/hogares/${h['id_hogar']}', {
                  'numero_hogar': numeroCtrl.text,
                  'responsable': responsableCtrl.text,
                  'direccion': direccionCtrl.text,
                  'telefono_contacto': telefonoCtrl.text,
                  'numero_habitantes': int.parse(habitantesCtrl.text),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Hogar actualizado'), backgroundColor: AppTheme.exito));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                }
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _eliminar(int idHogar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este hogar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ApiService.delete('/hogares/$idHogar');
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Hogar eliminado'), backgroundColor: AppTheme.exito));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

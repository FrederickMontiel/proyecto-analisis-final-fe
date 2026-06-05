import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});
  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<dynamic> _proveedores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final response = await ApiService.get('/proveedores');
      final lista = response is List ? response : (response['data'] as List? ?? []);
      setState(() { _proveedores = lista; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Proveedor'),
        backgroundColor: Colors.teal,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _proveedores.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(children: const [
                    SizedBox(height: 60),
                    Center(child: Icon(Icons.business, size: 64, color: Colors.grey)),
                    Center(child: Text('Sin proveedores registrados', style: TextStyle(color: Colors.grey))),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _proveedores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _cardProveedor(_proveedores[i]),
                  ),
                ),
    );
  }

  Widget _cardProveedor(Map<String, dynamic> p) {
    final activo = p['activo'] != false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: activo ? Colors.teal : Colors.grey, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nombre_proveedor']?.toString() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (p['especialidad'] != null) ...[
                      const SizedBox(height: 3),
                      Text('Especialidad: ${p['especialidad']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activo ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (p['telefono'] != null) Text('📞 ${p['telefono']}', style: const TextStyle(fontSize: 12)),
          if (p['correo'] != null) Text('📧 ${p['correo']}', style: const TextStyle(fontSize: 12)),
          if (p['descripcion'] != null) ...[
            const SizedBox(height: 6),
            Text(p['descripcion'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                onPressed: () => _mostrarFormulario(p),
              ),
              if (activo)
                TextButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Desactivar'),
                  onPressed: () => _desactivarProveedor(p['id_proveedor']),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarFormulario(Map<String, dynamic>? proveedor) {
    final nombreCtrl = TextEditingController(text: proveedor?['nombre_proveedor']?.toString());
    final especialidadCtrl = TextEditingController(text: proveedor?['especialidad']?.toString());
    final telefonoCtrl = TextEditingController(text: proveedor?['telefono']?.toString());
    final correoCtrl = TextEditingController(text: proveedor?['correo']?.toString());
    final descripcionCtrl = TextEditingController(text: proveedor?['descripcion']?.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(
          builder: (ctx2, setSt) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Proveedor *', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: especialidadCtrl,
                  decoration: const InputDecoration(labelText: 'Especialidad (ej: Plomería)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v!.isEmpty) return null;
                    if (!RegExp(r'^\d{8,15}$').hasMatch(v)) return 'Teléfono debe tener 8-15 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v!.isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        final data = {
                          'nombre_proveedor': nombreCtrl.text,
                          'especialidad': especialidadCtrl.text.isEmpty ? null : especialidadCtrl.text,
                          'telefono': telefonoCtrl.text.isEmpty ? null : telefonoCtrl.text,
                          'correo': correoCtrl.text.isEmpty ? null : correoCtrl.text,
                          'descripcion': descripcionCtrl.text.isEmpty ? null : descripcionCtrl.text,
                        };
                        if (proveedor == null) {
                          await ApiService.post('/proveedores', data);
                        } else {
                          await ApiService.put('/proveedores/${proveedor['id_proveedor']}', data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _cargar();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(proveedor == null ? 'Proveedor creado' : 'Proveedor actualizado'),
                            backgroundColor: AppTheme.exito,
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppTheme.error,
                          ));
                        }
                      }
                    },
                    child: Text(proveedor == null ? 'Crear' : 'Actualizar',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _desactivarProveedor(int id) async {
    try {
      await ApiService.delete('/proveedores/$id');
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor desactivado'), backgroundColor: AppTheme.exito),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

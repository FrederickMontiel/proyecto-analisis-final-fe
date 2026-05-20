import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;
  String _filtroRol = 'Todos';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/usuarios');
      setState(() { _usuarios = data as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  List<dynamic> get _filtrados => _filtroRol == 'Todos'
      ? _usuarios
      : _usuarios.where((u) => u['rol'] == _filtroRol).toList();

  Color _colorRol(String rol) {
    switch (rol) {
      case 'Presidente': return AppTheme.primario;
      case 'Tesorero': return Colors.green;
      case 'Operador': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _iconoRol(String rol) {
    switch (rol) {
      case 'Presidente': return Icons.admin_panel_settings;
      case 'Tesorero': return Icons.account_balance;
      case 'Operador': return Icons.engineering;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
        backgroundColor: AppTheme.primario,
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(children: ['Todos', 'Presidente', 'Tesorero', 'Operador', 'Habitante'].map((r) =>
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(r),
                selected: _filtroRol == r,
                onSelected: (_) => setState(() { _filtroRol = r; }),
                selectedColor: AppTheme.primario.withValues(alpha: 0.2),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _filtrados.isEmpty
                  ? const Center(child: Text('No hay usuarios'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = _filtrados[i];
                          final rol = u['rol']?.toString() ?? '';
                          final estado = u['estado']?.toString() ?? 'Activo';
                          final color = _colorRol(rol);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(_iconoRol(rol), color: color),
                            ),
                            title: Text(u['nombre']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${u['correo'] ?? ''} | ${u['telefono'] ?? ''}'),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(rol, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Text(estado, style: TextStyle(
                                  fontSize: 11,
                                  color: estado == 'Activo' ? AppTheme.exito : Colors.grey)),
                            ]),
                            onTap: () => _mostrarAcciones(u),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  void _mostrarAcciones(Map<String, dynamic> u) {
    final estado = u['estado']?.toString() ?? 'Activo';
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(u['nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
        const Divider(height: 1),
        if (estado == 'Activo')
          ListTile(
            leading: const Icon(Icons.person_off, color: AppTheme.error),
            title: const Text('Desactivar usuario'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ApiService.put('/usuarios/${u['id_usuario']}/desactivar', {});
                _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario desactivado'), backgroundColor: AppTheme.advertencia));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                }
              }
            },
          ),
        ListTile(
          leading: const Icon(Icons.close),
          title: const Text('Cancelar'),
          onTap: () => Navigator.pop(context),
        ),
      ]),
    );
  }

  void _mostrarFormulario() {
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'Habitante';
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(builder: (ctx2, setSt) => Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Crear Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: rol,
                items: ['Presidente', 'Tesorero', 'Operador', 'Habitante']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setSt(() { rol = v!; }),
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario, minimumSize: const Size(double.infinity, 52)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ApiService.post('/usuarios', {
                        'nombre': nombreCtrl.text,
                        'correo': correoCtrl.text,
                        'telefono': telCtrl.text,
                        'contrasena': passCtrl.text,
                        'rol': rol,
                        'estado': 'Activo',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _cargar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario creado'), backgroundColor: AppTheme.exito));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                      }
                    }
                  },
                  child: const Text('Crear Usuario', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        )),
      ),
    );
  }
}

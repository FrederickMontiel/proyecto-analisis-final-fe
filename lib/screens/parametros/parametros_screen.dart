import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});
  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  List<dynamic> _parametros = [];
  bool _cargando = true;
  String _categoriaFiltro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/parametros');
      setState(() { _parametros = data as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  List<dynamic> get _filtrados {
    if (_categoriaFiltro == 'Todos') return _parametros;
    return _parametros.where((p) => p['categoria'] == _categoriaFiltro).toList();
  }

  Color _colorCategoria(String cat) {
    switch (cat) {
      case 'Financiero': return Colors.green;
      case 'Operativo': return Colors.blue;
      case 'Alertas': return Colors.orange;
      default: return AppTheme.primario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ['Todos', 'Sistema', 'Financiero', 'Operativo', 'Alertas'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parámetros del Sistema'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categorias[i];
                return FilterChip(
                  label: Text(c),
                  selected: _categoriaFiltro == c,
                  onSelected: (selected) {
                    setState(() { _categoriaFiltro = c; });
                  },
                  selectedColor: AppTheme.primario.withValues(alpha: 0.2),
                );
              },
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(child: Text('No hay parámetros'))
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtrados.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = _filtrados[i];
                            final cat = p['categoria']?.toString() ?? '';
                            final color = _colorCategoria(cat);
                            final unidad = p['unidad_medida']?.toString() ?? '';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(Icons.tune, color: color, size: 20),
                              ),
                              title: Text(
                                p['clave']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              subtitle: Text(
                                p['descripcion']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    p['valor']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (unidad.isNotEmpty)
                                    Text(unidad, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              onTap: () => _editarParametro(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _editarParametro(Map<String, dynamic> param) {
    final valorCtrl = TextEditingController(text: param['valor']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final unidad = param['unidad_medida']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(param['clave']?.toString() ?? ''),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  param['descripcion']?.toString() ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (unidad.isNotEmpty)
                  Text('Unidad: $unidad', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Valor actual: ${param['valor']}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: valorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo valor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Ingrese un valor' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ApiService.put('/parametros/${param['id_parametro']}', {
                    'valor': valorCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _cargar();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Parámetro actualizado'),
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
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

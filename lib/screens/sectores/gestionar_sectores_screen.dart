import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class GestionarSectoresScreen extends StatefulWidget {
  const GestionarSectoresScreen({super.key});
  @override
  State<GestionarSectoresScreen> createState() => _GestionarSectoresScreenState();
}

class _GestionarSectoresScreenState extends State<GestionarSectoresScreen> {
  List<dynamic> _sectores = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/sectores');
      setState(() { _sectores = data as List; });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  int get _totalHogares => _sectores.fold(0, (s, sec) => s + (int.tryParse(sec['numero_hogares'].toString()) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Gestionar Sectores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF198754),
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
              // Resumen
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF198754),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.map, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_sectores.length} Sectores Activos',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$_totalHogares Hogares Totales',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargar,
                  child: _sectores.isEmpty
                      ? const Center(child: Text('No hay sectores registrados'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _sectores.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = _sectores[i];
                            return _cardSector(s, i);
                          },
                        ),
                ),
              ),
            ]),
    );
  }

  Widget _cardSector(Map<String, dynamic> s, int idx) {
    final colores = [
      const Color(0xFF198754), const Color(0xFF0D6EFD), const Color(0xFFFD7E14),
      const Color(0xFF6F42C1), const Color(0xFF0DCAF0),
    ];
    final color = colores[idx % colores.length];
    final hogares = int.tryParse(s['numero_hogares'].toString()) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), radius: 20,
              child: Text('S${idx + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['nombre_sector']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (s['descripcion'] != null && s['descripcion'].toString().isNotEmpty)
              Text(s['descripcion'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFD1E7DD), borderRadius: BorderRadius.circular(12)),
            child: const Text('Activo', style: TextStyle(color: Color(0xFF198754), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 20),
        Row(children: [
          _statChip(Icons.home, '$hogares Hogares', color),
          const SizedBox(width: 8),
          _statChip(Icons.people, '${hogares * 4} Habitantes (est.)', color),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _mostrarEditar(s),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _asignarHogares(s['id_sector']),
              icon: const Icon(Icons.home_work, size: 16, color: Colors.white),
              label: const Text('Hogares', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
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

  void _mostrarFormulario() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Sector'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del Sector *', border: OutlineInputBorder(),
                  hintText: 'Ej: Sector 6'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción',
                  border: OutlineInputBorder(), hintText: 'Descripción de la ubicación...'),
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
                await ApiService.post('/sectores', {
                  'nombre_sector': nombreCtrl.text,
                  'descripcion': descCtrl.text,
                  'estado': 'Activo',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sector creado'), backgroundColor: AppTheme.exito));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                }
              }
            },
            child: const Text('Crear Sector', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarEditar(Map<String, dynamic> s) {
    final nombreCtrl = TextEditingController(text: s['nombre_sector']?.toString() ?? '');
    final descCtrl = TextEditingController(text: s['descripcion']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Sector'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: descCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.put('/sectores/${s['id_sector']}', {
                  'nombre_sector': nombreCtrl.text,
                  'descripcion': descCtrl.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sector actualizado'), backgroundColor: AppTheme.exito));
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

  void _asignarHogares(int idSector) async {
    showDialog(
      context: context,
      builder: (ctx) => _AsignarHogaresDialog(idSector: idSector, onSuccess: _cargar),
    );
  }
}

class _AsignarHogaresDialog extends StatefulWidget {
  final int idSector;
  final VoidCallback onSuccess;
  const _AsignarHogaresDialog({required this.idSector, required this.onSuccess});
  @override
  State<_AsignarHogaresDialog> createState() => _AsignarHogaresDialogState();
}

class _AsignarHogaresDialogState extends State<_AsignarHogaresDialog> {
  late Future<Map<String, dynamic>> _dataFuture;
  late Set<int> _seleccionados;

  @override
  void initState() {
    super.initState();
    _dataFuture = ApiService.get('/sectores/${widget.idSector}/hogares').then((data) => data as Map<String, dynamic>);
    _seleccionados = {};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Hogares'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, size: 32, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              );
            }
            final data = snapshot.data ?? {};
            final hogares = (data['hogares'] as List? ?? []).cast<Map<String, dynamic>>();
            _seleccionados = Set.from(hogares.where((h) => h['asignado'] == true).map((h) => h['id_hogar'] as int));
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${hogares.length} hogares disponibles', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                if (hogares.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('Sin hogares registrados', style: TextStyle(color: Colors.grey)))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: hogares.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final h = hogares[i];
                        final id = h['id_hogar'] as int;
                        final nombre = h['numero_hogar'] ?? 'Hogar sin nombre';
                        final asignado = _seleccionados.contains(id);
                        return CheckboxListTile(
                          value: asignado,
                          onChanged: (v) => setState(() {
                            if (v == true) _seleccionados.add(id);
                            else _seleccionados.remove(id);
                          }),
                          title: Text(nombre.toString(), style: const TextStyle(fontSize: 13)),
                          subtitle: Text('ID: $id', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.exito),
          onPressed: () async {
            final nav = Navigator.of(context);
            final scaffold = ScaffoldMessenger.of(context);
            try {
              await ApiService.post('/sectores/${widget.idSector}/asignar-hogares', {
                'idsHogares': _seleccionados.toList(),
              });
              if (!mounted) return;
              nav.pop();
              widget.onSuccess();
              scaffold.showSnackBar(
                const SnackBar(content: Text('Hogares asignados'), backgroundColor: AppTheme.exito),
              );
            } catch (e) {
              if (!mounted) return;
              scaffold.showSnackBar(
                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error),
              );
            }
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

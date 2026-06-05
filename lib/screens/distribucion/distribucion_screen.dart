import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class DistribucionScreen extends StatefulWidget {
  const DistribucionScreen({super.key});
  @override
  State<DistribucionScreen> createState() => _DistribucionScreenState();
}

class _DistribucionScreenState extends State<DistribucionScreen> {
  List<dynamic> _calendarios = [];
  bool _cargando = true;

  static const List<String> _diasSemana = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/distribucion/calendarios');
      print('DEBUG calendarios response: $data');
      setState(() { _calendarios = data is List ? data : (data?['data'] ?? []); });
    } catch (e) {
      print('ERROR cargando calendarios: $e');
    }
    setState(() { _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Distribución', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCalendario(null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Calendario'),
        backgroundColor: Colors.teal,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _calendarios.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(children: const [
                    SizedBox(height: 60),
                    Center(child: Icon(Icons.calendar_today, size: 64, color: Colors.grey)),
                    Center(child: Text('Sin calendarios registrados', style: TextStyle(color: Colors.grey))),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _calendarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _cardCalendario(_calendarios[i]),
                  ),
                ),
    );
  }

  Widget _cardCalendario(Map<String, dynamic> cal) {
    final detalles = (cal['detalles'] as List? ?? []).cast<Map<String, dynamic>>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(cal['nombre_calendario']?.toString() ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${detalles.length} horarios registrados'),
            trailing: const Icon(Icons.schedule),
          ),
          if (cal['descripcion'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(cal['descripcion'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          if (detalles.isNotEmpty)
            ...detalles.map((detalle) => _itemDetalle(detalle, cal['id_calendario']))
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin horarios asignados', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar Horario'),
                    onPressed: () => _mostrarFormularioDetalle(cal['id_calendario'], null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    onPressed: () => _mostrarFormularioCalendario(cal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemDetalle(Map<String, dynamic> detalle, int idCalendario) {
    final sector = detalle['sector'] as Map<String, dynamic>? ?? {};
    final dia = _diasSemana[detalle['dia_semana'] as int? ?? 0];
    final inicio = detalle['hora_inicio']?.toString().substring(0, 5) ?? '00:00';
    final fin = detalle['hora_fin']?.toString().substring(0, 5) ?? '00:00';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dia, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${sector['nombre_sector'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('$inicio - $fin', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.teal)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _mostrarFormularioDetalle(idCalendario, detalle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _eliminarDetalle(detalle['id_detalle']),
                  ),
                ],
              ),
            ],
          ),
          if (detalle['descripcion'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(detalle['descripcion'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  void _mostrarFormularioCalendario(Map<String, dynamic>? calendario) {
    final nombreCtrl = TextEditingController(text: calendario?['nombre_calendario']?.toString());
    final descCtrl = TextEditingController(text: calendario?['descripcion']?.toString());
    final fechaInicioCtrl = TextEditingController(text: calendario?['fecha_inicio_vigencia']?.toString() ?? DateTime.now().toString().split(' ')[0]);
    final fechaFinCtrl = TextEditingController(text: calendario?['fecha_fin_vigencia']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(calendario == null ? 'Nuevo Calendario' : 'Editar Calendario',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Calendario *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaInicioCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha Inicio *', suffixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onTap: () async {
                  final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (date != null) fechaInicioCtrl.text = date.toString().split(' ')[0];
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaFinCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha Fin (opcional)', suffixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                onTap: () async {
                  final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (date != null) fechaFinCtrl.text = date.toString().split(' ')[0];
                },
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
                        'nombre_calendario': nombreCtrl.text,
                        'descripcion': descCtrl.text.isEmpty ? null : descCtrl.text,
                        'fecha_inicio_vigencia': fechaInicioCtrl.text,
                        'fecha_fin_vigencia': fechaFinCtrl.text.isEmpty ? null : fechaFinCtrl.text,
                      };
                      if (calendario == null) {
                        await ApiService.post('/distribucion/calendarios', data);
                      } else {
                        await ApiService.put('/distribucion/calendarios/${calendario['id_calendario']}', data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _cargar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(calendario == null ? 'Calendario creado' : 'Calendario actualizado'),
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
                  child: Text(calendario == null ? 'Crear' : 'Actualizar',
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioDetalle(int idCalendario, Map<String, dynamic>? detalle) async {
    final sectores = await _cargarSectores();
    if (!mounted) return;

    final diaCtrl = TextEditingController(text: detalle?['dia_semana']?.toString() ?? '1');
    final horaInicioCtrl = TextEditingController(text: detalle?['hora_inicio']?.toString().substring(0, 5) ?? '06:00');
    final horaFinCtrl = TextEditingController(text: detalle?['hora_fin']?.toString().substring(0, 5) ?? '12:00');
    final descCtrl = TextEditingController(text: detalle?['descripcion']?.toString());
    int? idSectorSeleccionado = detalle?['id_sector'] as int?;
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
                Text(detalle == null ? 'Nuevo Horario' : 'Editar Horario',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: idSectorSeleccionado,
                  items: sectores.map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(value: s['id_sector'] as int, child: Text(s['nombre_sector'] ?? 'N/A'))).toList(),
                  onChanged: (v) => setSt(() { idSectorSeleccionado = v; }),
                  decoration: const InputDecoration(labelText: 'Sector *', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Seleccione sector' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: int.tryParse(diaCtrl.text),
                  items: List<DropdownMenuItem<int>>.generate(7, (i) => DropdownMenuItem<int>(value: i, child: Text(_diasSemana[i]))),
                  onChanged: (v) {
                    if (v != null) {
                      diaCtrl.text = v.toString();
                      setSt(() {});
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Día de la Semana *', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Seleccione día' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: horaInicioCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Hora Inicio *', suffixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerida' : null,
                  onTap: () async {
                    final t = await showTimePicker(context: ctx2, initialTime: TimeOfDay.now());
                    if (t != null) {
                      horaInicioCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: horaFinCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Hora Fin *', suffixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerida' : null,
                  onTap: () async {
                    final t = await showTimePicker(context: ctx2, initialTime: TimeOfDay.now());
                    if (t != null) {
                      horaFinCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
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
                          'id_sector': idSectorSeleccionado,
                          'dia_semana': int.parse(diaCtrl.text),
                          'hora_inicio': '${horaInicioCtrl.text}:00',
                          'hora_fin': '${horaFinCtrl.text}:00',
                          'descripcion': descCtrl.text.isEmpty ? null : descCtrl.text,
                        };
                        if (detalle == null) {
                          await ApiService.post('/distribucion/calendarios/$idCalendario/detalles', data);
                        } else {
                          await ApiService.put('/distribucion/detalles/${detalle['id_detalle']}', data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _cargar();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(detalle == null ? 'Horario agregado' : 'Horario actualizado'),
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
                    child: Text(detalle == null ? 'Agregar' : 'Actualizar',
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

  Future<List<dynamic>> _cargarSectores() async {
    try {
      return await ApiService.get('/sectores') ?? [];
    } catch (_) {
      return [];
    }
  }

  void _eliminarDetalle(int idDetalle) async {
    try {
      await ApiService.delete('/distribucion/detalles/$idDetalle');
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario eliminado'), backgroundColor: AppTheme.exito),
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

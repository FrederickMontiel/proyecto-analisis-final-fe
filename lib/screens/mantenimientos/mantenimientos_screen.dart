import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/file_service.dart';
import '../../services/proveedores_service.dart';
import '../../services/debug_service.dart';
import '../../services/web_file_picker.dart';

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
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () => DebugService.showLogsDialog(context),
          ),
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
    final proveedor = m['proveedor'] as Map<String, dynamic>?;
    final componente = m['componente']?.toString();
    final duracion = double.tryParse(m['duracion_horas']?.toString() ?? '0');
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
        if (componente != null && componente.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('Componente: $componente', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
        if (proveedor != null) ...[
          const SizedBox(height: 3),
          Text('Proveedor: ${proveedor['nombre_proveedor'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
        if (duracion != null && duracion > 0) ...[
          const SizedBox(height: 3),
          Text('Duración: ${duracion.toStringAsFixed(1)} horas',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
        if (costo > 0) ...[
          const SizedBox(height: 4),
          Text('Costo: Q ${costo.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  void _mostrarFormulario() async {
    final descCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final horaInicioCtrl = TextEditingController(text: '08:00');
    final horaFinCtrl = TextEditingController();
    final materialesCtrl = TextEditingController();
    String tipo = 'Preventivo';
    String componente = 'Tanques';
    int? idProveedorSeleccionado;
    String? fotoUrl;
    final formKey = GlobalKey<FormState>();
    final proveedores = await ProveedoresService.obtenerProveedores();

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
              const Text('Proveedor/Responsable', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: idProveedorSeleccionado,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('Seleccione un proveedor...')),
                  ...proveedores.map((p) => DropdownMenuItem<int>(
                    value: p['id_proveedor'] as int,
                    child: Text(p['nombre_proveedor']?.toString() ?? 'Sin nombre'),
                  )),
                ],
                onChanged: (v) => setSt(() { idProveedorSeleccionado = v; }),
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Seleccione...'),
              ),
              if (idProveedorSeleccionado != null && proveedores.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...proveedores
                          .where((p) => p['id_proveedor'] == idProveedorSeleccionado)
                          .map((p) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p['especialidad'] != null)
                                Text('Especialidad: ${p['especialidad']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (p['telefono'] != null)
                                Text('Tel: ${p['telefono']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (p['correo'] != null)
                                Text('Email: ${p['correo']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Fecha del Mantenimiento *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: fechaCtrl,
                readOnly: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                validator: (v) => v!.isEmpty ? 'Fecha requerida' : null,
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
                  const Text('Hora de Inicio *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: horaInicioCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.schedule)),
                    validator: (v) => v!.isEmpty ? 'Requerida' : null,
                    onTap: () async {
                      final time = await showTimePicker(context: ctx2, initialTime: const TimeOfDay(hour: 8, minute: 0));
                      if (time != null) {
                        horaInicioCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setSt(() {});
                      }
                    },
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Hora de Finalización *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: horaFinCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.schedule)),
                    validator: (v) => v!.isEmpty ? 'Requerida' : null,
                    onTap: () async {
                      final time = await showTimePicker(context: ctx2, initialTime: const TimeOfDay(hour: 9, minute: 0));
                      if (time != null) {
                        horaFinCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setSt(() {});
                      }
                    },
                  ),
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
                validator: (v) {
                  if (v!.isEmpty) return null;
                  final cost = double.tryParse(v);
                  if (cost == null) return 'Ingrese un número válido';
                  if (cost < 0) return 'Costo no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text('Foto de evidencia', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.spaceBetween, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.image, color: fotoUrl != null ? Colors.blue : Colors.grey),
                    const SizedBox(width: 6),
                    Text(fotoUrl != null ? 'Foto adjuntada' : 'Sin foto', style: const TextStyle(fontSize: 14)),
                  ]),
                  ElevatedButton.icon(
                    onPressed: () async {
                      DebugService.log('FilePicker: onClick');
                      try {
                        DebugService.log('FilePicker: picking, kIsWeb=$kIsWeb');
                        dynamic uploadData;
                        String? fileName;

                        if (kIsWeb) {
                          DebugService.log('FilePicker: using WebFilePicker');
                          final webResult = await WebFilePicker.pickFile(allowedExtensions: ['jpg', 'jpeg', 'png']);
                          if (webResult != null) {
                            DebugService.log('FilePicker: web file selected=${webResult.name}, bytes=${webResult.bytes.length}');
                            uploadData = webResult.bytes;
                            fileName = webResult.name;
                          } else {
                            DebugService.log('FilePicker: web canceled');
                            return;
                          }
                        } else {
                          DebugService.log('FilePicker: using FilePicker.platform');
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png'],
                            withData: true,
                          );
                          DebugService.log('FilePicker: result=$result');
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            DebugService.log('FilePicker: ${file.name}, size=${file.size}, bytes=${file.bytes != null}');

                            if (file.bytes != null) {
                              DebugService.log('FilePicker: using bytes');
                              uploadData = file.bytes!;
                            } else if (file.readStream != null) {
                              DebugService.log('FilePicker: using readStream');
                              uploadData = file.readStream;
                            } else if (file.path != null) {
                              DebugService.log('FilePicker: using file.path');
                              uploadData = File(file.path!);
                            } else {
                              DebugService.log('FilePicker: no data available');
                              return;
                            }
                            fileName = file.name;
                          } else {
                            DebugService.log('FilePicker: mobile canceled');
                            return;
                          }
                        }

                        DebugService.log('FilePicker: uploading $fileName');
                        final url = await FileService.uploadImage(uploadData, fileName: fileName);
                        DebugService.log('FilePicker: url=$url');

                        if (url != null) {
                          setSt(() { fotoUrl = url; });
                          if (ctx2.mounted) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(content: Text('Foto cargada'), backgroundColor: AppTheme.exito, duration: Duration(seconds: 2))
                            );
                          }
                        } else {
                          if (ctx2.mounted) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(content: Text('Error al cargar foto'), backgroundColor: AppTheme.error, duration: Duration(seconds: 2))
                            );
                          }
                        }
                      } catch (e) {
                        DebugService.log('FilePicker: $e');
                      }
                    },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Seleccionar Foto'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  ),
                ]),
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
                      double? duracionHoras;
                      if (horaInicioCtrl.text.isNotEmpty && horaFinCtrl.text.isNotEmpty) {
                        final inicio = horaInicioCtrl.text.split(':');
                        final fin = horaFinCtrl.text.split(':');
                        if (inicio.length == 2 && fin.length == 2) {
                          final minInicio = int.parse(inicio[0]) * 60 + int.parse(inicio[1]);
                          final minFin = int.parse(fin[0]) * 60 + int.parse(fin[1]);
                          duracionHoras = (minFin - minInicio) / 60.0;
                          if (duracionHoras < 0) duracionHoras += 24;
                        }
                      }
                      await ApiService.post('/mantenimientos', {
                        'tipo_mantenimiento': tipo,
                        'descripcion': descCtrl.text,
                        'fecha_realizacion': fechaCtrl.text,
                        'costo': double.tryParse(costoCtrl.text),
                        'observaciones': materialesCtrl.text,
                        'id_usuario': AuthService.usuario!.idUsuario,
                        'id_proveedor': idProveedorSeleccionado,
                        'componente': componente,
                        'duracion_horas': duracionHoras,
                        'foto_url': fotoUrl,
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

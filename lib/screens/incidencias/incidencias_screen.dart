import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/file_service.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});
  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  List<dynamic> _incidencias = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/incidencias');
      setState(() {
        _incidencias = ((data as List).where((i) =>
            i['estado'] != 'Resuelta' && i['estado'] != 'Cancelada').toList())
            .reversed.toList();
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Reportada': return Colors.orange;
      case 'EnRevisión': return Colors.blue;
      case 'EnAtención': return Colors.purple;
      case 'Resuelta': return AppTheme.exito;
      case 'Cancelada': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _colorUrgencia(String u) {
    switch (u) {
      case 'Alta': return AppTheme.error;
      case 'Media': return AppTheme.advertencia;
      default: return AppTheme.exito;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = AuthService.usuario?.rol ?? '';
    final puedeReportar = true;
    final puedeGestionar = rol == 'Presidente' || rol == 'Operador';
    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: puedeReportar
          ? FloatingActionButton.extended(
              onPressed: _mostrarFormularioReporte,
              icon: const Icon(Icons.report_problem),
              label: const Text('Reportar'),
              backgroundColor: Colors.orange,
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _incidencias.isEmpty
              ? const Center(child: Text('No hay incidencias registradas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _incidencias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _cardIncidencia(_incidencias[i], puedeGestionar),
                  ),
                ),
    );
  }

  Widget _cardIncidencia(Map<String, dynamic> inc, bool puedeGestionar) {
    final estado = inc['estado']?.toString() ?? '';
    final urgencia = inc['nivel_urgencia']?.toString() ?? 'Media';
    final colorEstado = _colorEstado(estado);
    final fecha = inc['fecha_reporte']?.toString().substring(0, 10) ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(inc['numero_incidencia']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(estado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(inc['ubicacion']?.toString() ?? '', style: const TextStyle(fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _colorUrgencia(urgencia).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(urgencia, style: TextStyle(color: _colorUrgencia(urgencia), fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(inc['descripcion']?.toString() ?? '', style: const TextStyle(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Tipo: ${inc['tipo_incidencia']} | $fecha', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (puedeGestionar && estado != 'Resuelta' && estado != 'Cancelada') ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              if (estado == 'Reportada') OutlinedButton(
                onPressed: () => _cambiarEstado(inc['id_incidencia'], 'EnRevisión'),
                child: const Text('En Revisión'),
              ),
              if (estado == 'EnRevisión') OutlinedButton(
                onPressed: () => _cambiarEstado(inc['id_incidencia'], 'EnAtención'),
                child: const Text('Atender'),
              ),
              if (estado == 'EnAtención') ElevatedButton(
                onPressed: () => _cambiarEstado(inc['id_incidencia'], 'Resuelta'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.exito),
                child: const Text('Resolver', style: TextStyle(color: Colors.white)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      await ApiService.put('/incidencias/$id', {'estado': nuevoEstado});
      _cargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $nuevoEstado'), backgroundColor: AppTheme.exito));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
    }
  }

  void _mostrarFormularioReporte() {
    final descCtrl = TextEditingController();
    final ubCtrl = TextEditingController();
    String tipo = 'Fuga';
    String urgencia = 'Media';
    String? fotoUrl;
    File? fotoLocal;
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
            const Text('Reportar Incidencia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tipo,
              items: ['Fuga', 'Bomba', 'Válvula', 'SinSuministro', 'Otro']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setSt(() { tipo = v!; }),
              decoration: const InputDecoration(labelText: 'Tipo de problema', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ubCtrl,
              decoration: const InputDecoration(labelText: 'Ubicación / Referencia', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Ingrese la ubicación' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción del problema', border: OutlineInputBorder()),
              validator: (v) => v!.length < 10 ? 'Agregue más detalles (mín. 10 caracteres)' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: urgencia,
              items: ['Baja', 'Media', 'Alta'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setSt(() { urgencia = v!; }),
              decoration: const InputDecoration(labelText: 'Urgencia', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.spaceBetween, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.image, color: fotoUrl != null ? AppTheme.exito : Colors.grey),
                  const SizedBox(width: 6),
                  Text(fotoUrl != null ? 'Foto adjuntada' : 'Sin foto', style: const TextStyle(fontSize: 14)),
                ]),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (foto != null) {
                      fotoLocal = File(foto.path);
                      final url = await FileService.uploadImage(fotoLocal!);
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
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Capturar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final numero = 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    await ApiService.post('/incidencias', {
                      'numero_incidencia': numero,
                      'tipo_incidencia': tipo,
                      'descripcion': descCtrl.text,
                      'ubicacion': ubCtrl.text,
                      'nivel_urgencia': urgencia,
                      'estado': 'Reportada',
                      'id_usuario_reporta': AuthService.usuario!.idUsuario,
                      'foto_url': fotoUrl,
                    });
                    Navigator.pop(ctx);
                    _cargar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incidencia reportada'), backgroundColor: AppTheme.exito));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Enviar Reporte', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

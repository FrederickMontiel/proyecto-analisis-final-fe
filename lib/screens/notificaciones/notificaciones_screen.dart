import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});
  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<dynamic> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/notificaciones');
      setState(() { _notificaciones = (data as List).reversed.toList(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Alerta': return AppTheme.error;
      case 'Urgente': return AppTheme.error;
      case 'Recordatorio': return AppTheme.advertencia;
      default: return AppTheme.primario;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'Alerta': return Icons.warning;
      case 'Recordatorio': return Icons.alarm;
      case 'Sistema': return Icons.settings;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPresidente = AuthService.usuario?.esPresidente ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: esPresidente
          ? FloatingActionButton.extended(
              onPressed: _mostrarFormularioMasivo,
              icon: const Icon(Icons.send),
              label: const Text('Envío Masivo'),
              backgroundColor: AppTheme.primario,
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No hay notificaciones'),
                ]))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = _notificaciones[i];
                      final tipo = n['tipo']?.toString() ?? 'Sistema';
                      final color = _colorTipo(tipo);
                      final leida = n['leida'] == true;
                      final fecha = n['fecha_envio']?.toString().substring(0, 16) ?? '';
                      return ListTile(
                        tileColor: leida ? null : color.withValues(alpha: 0.05),
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(_iconoTipo(tipo), color: color),
                        ),
                        title: Row(children: [
                          if (!leida) Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          Expanded(child: Text(n['titulo']?.toString() ?? '',
                              style: TextStyle(fontWeight: leida ? FontWeight.normal : FontWeight.bold))),
                        ]),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['mensaje']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(fecha, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        onTap: () async {
                          if (!leida) {
                            await ApiService.put('/notificaciones/${n['id_notificacion']}', {
                              'leida': true,
                              'fecha_lectura': DateTime.now().toIso8601String(),
                            });
                            _cargar();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  void _mostrarFormularioMasivo() {
    final tituloCtrl = TextEditingController();
    final mensajeCtrl = TextEditingController();
    String tipo = 'Informativo';
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
            const Text('Enviar Notificación Masiva', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Se enviará a todos los usuarios del sistema', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tipo,
              items: ['Informativo', 'Alerta', 'Recordatorio', 'Sistema']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setSt(() { tipo = v!; }),
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: mensajeCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar a Todos', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario, minimumSize: const Size(double.infinity, 52)),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ApiService.post('/notificaciones', {
                      'tipo': tipo,
                      'titulo': tituloCtrl.text,
                      'mensaje': mensajeCtrl.text,
                      'id_usuario_destino': AuthService.usuario!.idUsuario,
                      'leida': false,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notificación enviada'), backgroundColor: AppTheme.exito));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

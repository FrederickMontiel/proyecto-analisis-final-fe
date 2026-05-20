import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});
  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  List<dynamic> _logs = [];
  bool _cargando = true;
  final _buscarCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/auditoria');
      setState(() { _logs = (data as List).reversed.toList(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  List<dynamic> get _filtrados => _busqueda.isEmpty
      ? _logs
      : _logs.where((l) =>
          (l['accion']?.toString().toLowerCase().contains(_busqueda.toLowerCase()) ?? false) ||
          (l['tabla_afectada']?.toString().toLowerCase().contains(_busqueda.toLowerCase()) ?? false)).toList();

  Color _colorAccion(String accion) {
    if (accion.toLowerCase().contains('crear') || accion.toLowerCase().contains('insert')) return AppTheme.exito;
    if (accion.toLowerCase().contains('eliminar') || accion.toLowerCase().contains('delete')) return AppTheme.error;
    if (accion.toLowerCase().contains('actualizar') || accion.toLowerCase().contains('update')) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log de Auditoría'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _buscarCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por acción o tabla...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear),
                      onPressed: () { _buscarCtrl.clear(); setState(() { _busqueda = ''; }); })
                  : null,
            ),
            onChanged: (v) => setState(() { _busqueda = v; }),
          ),
        ),
        if (!_cargando)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_filtrados.length} registros', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _filtrados.isEmpty
                  ? const Center(child: Text('Sin registros de auditoría'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final l = _filtrados[i];
                          final accion = l['accion']?.toString() ?? '';
                          final tabla = l['tabla_afectada']?.toString() ?? '';
                          final color = _colorAccion(accion);
                          final fecha = l['fecha_hora']?.toString().substring(0, 16) ?? '';
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.history, color: color, size: 18),
                            ),
                            title: Text(accion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Tabla: $tabla | $fecha', style: const TextStyle(fontSize: 12)),
                            trailing: l['descripcion'] != null
                                ? const Icon(Icons.info_outline, size: 18, color: Colors.grey)
                                : null,
                            onTap: l['descripcion'] != null
                                ? () => showDialog(context: context, builder: (_) => AlertDialog(
                                    title: Text(accion),
                                    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Tabla: $tabla'),
                                      if (l['valor_anterior'] != null)
                                        Text('Antes: ${l['valor_anterior']}', style: const TextStyle(color: Colors.red)),
                                      if (l['valor_nuevo'] != null)
                                        Text('Después: ${l['valor_nuevo']}', style: const TextStyle(color: Colors.green)),
                                      Text('Descripción: ${l['descripcion']}'),
                                      Text('Fecha: $fecha'),
                                    ]),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                                  ))
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

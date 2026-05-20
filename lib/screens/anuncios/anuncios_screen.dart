import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});
  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  List<dynamic> _anuncios = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final data = await ApiService.get('/anuncios');
      setState(() { _anuncios = (data as List).reversed.toList(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Urgente': return AppTheme.error;
      case 'Mantenimiento': return Colors.orange;
      default: return AppTheme.primario;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'Urgente': return Icons.warning;
      case 'Mantenimiento': return Icons.build;
      default: return Icons.announcement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPresidente = AuthService.usuario?.esPresidente ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      floatingActionButton: esPresidente
          ? FloatingActionButton.extended(
              onPressed: _mostrarFormulario,
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
              backgroundColor: AppTheme.primario,
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _anuncios.isEmpty
              ? const Center(child: Text('No hay anuncios publicados'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _anuncios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _cardAnuncio(_anuncios[i]),
                  ),
                ),
    );
  }

  Widget _cardAnuncio(Map<String, dynamic> a) {
    final tipo = a['tipo']?.toString() ?? 'Informativo';
    final color = _colorTipo(tipo);
    final vigencia = a['fecha_vigencia']?.toString().substring(0, 10) ?? '';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_iconoTipo(tipo), color: color, size: 24),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(tipo, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const Spacer(),
            Text('Vigente hasta: $vigencia', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(a['titulo']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(a['contenido']?.toString() ?? '', style: const TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }

  void _mostrarFormulario() {
    final tituloCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();
    final vigenciaCtrl = TextEditingController();
    String tipoSel = 'Informativo';
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
            const Text('Publicar Anuncio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contenidoCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Contenido', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoSel,
              items: ['Informativo', 'Urgente', 'Mantenimiento']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setSt(() { tipoSel = v!; }),
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: vigenciaCtrl,
              decoration: const InputDecoration(labelText: 'Vigente hasta (YYYY-MM-DD)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
              onTap: () async {
                final d = await showDatePicker(context: ctx2, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) vigenciaCtrl.text = d.toIso8601String().substring(0, 10);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ApiService.post('/anuncios', {
                      'titulo': tituloCtrl.text,
                      'contenido': contenidoCtrl.text,
                      'tipo': tipoSel,
                      'fecha_vigencia': vigenciaCtrl.text,
                      'id_usuario_publica': AuthService.usuario!.idUsuario,
                      'enviar_notificacion': false,
                      'estado': 'Activo',
                    });
                    Navigator.pop(ctx);
                    _cargar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Anuncio publicado'), backgroundColor: AppTheme.exito));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
                child: const Text('Publicar', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class RegistrarNivelScreen extends StatefulWidget {
  const RegistrarNivelScreen({super.key});
  @override
  State<RegistrarNivelScreen> createState() => _RegistrarNivelScreenState();
}

class _RegistrarNivelScreenState extends State<RegistrarNivelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nivelCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  List<dynamic> _tanques = [];
  int? _idTanque;
  bool _cargando = false;
  bool _guardando = false;
  Map<String, dynamic>? _ultimoNivel;

  @override
  void initState() {
    super.initState();
    _cargarTanques();
  }

  Future<void> _cargarTanques() async {
    setState(() { _cargando = true; });
    try {
      final t = await ApiService.get('/tanques');
      final n = await ApiService.get('/niveles');
      setState(() {
        _tanques = t as List;
        if (_tanques.isNotEmpty) _idTanque = _tanques.first['id_tanque'];
        final lista = (n as List);
        if (lista.isNotEmpty) _ultimoNivel = lista.last;
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final nivel = double.tryParse(_nivelCtrl.text) ?? 0;
    final ultimo = double.tryParse(_ultimoNivel?['nivel_porcentaje']?.toString() ?? '0') ?? 0;
    if ((nivel - ultimo).abs() > 30) {
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Cambio drástico'),
        content: Text('El nivel cambió ${(nivel - ultimo).abs().toStringAsFixed(0)}%. ¿Confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ));
      if (ok != true) return;
    }
    setState(() { _guardando = true; });
    try {
      final tanque = _tanques.firstWhere((t) => t['id_tanque'] == _idTanque);
      final litros = (nivel * double.parse(tanque['capacidad_litros'].toString())) / 100;
      String estado = 'Normal';
      if (nivel <= 20) estado = 'Crítico';
      else if (nivel <= 40) estado = 'Alerta';
      await ApiService.post('/niveles', {
        'id_tanque': _idTanque,
        'nivel_porcentaje': nivel,
        'nivel_litros': litros,
        'observaciones': _obsCtrl.text,
        'id_usuario': AuthService.usuario!.idUsuario,
        'estado': estado,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nivel registrado: $nivel%'), backgroundColor: AppTheme.exito));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() { _guardando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nivel de Agua')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_ultimoNivel != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Último nivel: ${_ultimoNivel!['nivel_porcentaje']}% — ${_ultimoNivel!['nivel_litros']} L'),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_tanques.isNotEmpty) ...[
                    const Text('Tanque', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _idTanque,
                      items: _tanques.map<DropdownMenuItem<int>>((t) =>
                        DropdownMenuItem(value: t['id_tanque'] as int, child: Text(t['nombre_tanque'].toString()))).toList(),
                      onChanged: (v) => setState(() { _idTanque = v; }),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Nivel medido (%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nivelCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24),
                    decoration: const InputDecoration(
                      hintText: '0 - 100',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingrese el nivel';
                      final n = double.tryParse(v);
                      if (n == null) return 'Ingrese un número válido';
                      if (n < 0 || n > 100) return 'El nivel debe estar entre 0 y 100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Bomba estuvo apagada 2 horas',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_guardando ? 'Guardando...' : 'Registrar Nivel', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}

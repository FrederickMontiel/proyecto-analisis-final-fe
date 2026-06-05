import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String mesSeleccionado = '';

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    fechaInicio = DateTime(hoy.year, hoy.month, 1);
    fechaFin = hoy;
    mesSeleccionado = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transparencia Financiera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: fechaInicio!,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() { fechaInicio = d; });
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Desde',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(fechaInicio?.toString().substring(0, 10) ?? ''),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: fechaFin!,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() { fechaFin = d; });
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hasta',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(fechaFin?.toString().substring(0, 10) ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Descargar PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () => _descargarTransparencia(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consumo de Agua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: mesSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Mes (YYYY-MM)',
                      hintText: '2026-06',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => mesSeleccionado = v,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('Descargar PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () => _descargarConsumo(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _descargarTransparencia() async {
    if (fechaInicio == null || fechaFin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione fechas'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    try {
      final inicio = fechaInicio!.toIso8601String().substring(0, 10);
      final fin = fechaFin!.toIso8601String().substring(0, 10);
      final url = '/reportes/transparencia?fechaInicio=$inicio&fechaFin=$fin';
      await ApiService.descargarArchivo(url, 'transparencia-$inicio-$fin.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descargado'), backgroundColor: AppTheme.exito),
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

  void _descargarConsumo() async {
    if (mesSeleccionado.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese mes'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    try {
      final url = '/reportes/consumo?mes=$mesSeleccionado';
      await ApiService.descargarArchivo(url, 'consumo-$mesSeleccionado.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descargado'), backgroundColor: AppTheme.exito),
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

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
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
      setState(() { _calendarios = data is List ? data : (data?['data'] ?? []); });
    } catch (e) {
      print('Error cargando calendarios: $e');
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _calendarios.isEmpty
              ? RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(children: const [
                    SizedBox(height: 60),
                    Center(child: Icon(Icons.calendar_today, size: 64, color: Colors.grey)),
                    Center(child: Text('Sin calendarios de distribución', style: TextStyle(color: Colors.grey))),
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
            subtitle: Text('${detalles.length} horarios'),
            trailing: const Icon(Icons.schedule),
          ),
          if (cal['descripcion'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(cal['descripcion'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          if (detalles.isNotEmpty)
            ...detalles.map((detalle) => _itemDetalle(detalle))
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin horarios', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _itemDetalle(Map<String, dynamic> detalle) {
    final sector = detalle['sector'] as Map<String, dynamic>? ?? {};
    final dia = _diasSemana[detalle['dia_semana'] as int? ?? 0];
    final inicio = detalle['hora_inicio']?.toString().substring(0, 5) ?? '00:00';
    final fin = detalle['hora_fin']?.toString().substring(0, 5) ?? '00:00';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
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
}

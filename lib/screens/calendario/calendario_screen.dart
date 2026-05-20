import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  String _sectorSel = 'Sector 2';
  final _sectores = ['Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Sector 5'];

  // Calendario estático semanal de distribución
  List<Map<String, dynamic>> get _semanaActual {
    final hoy = DateTime.now();
    return [
      {
        'fecha': _formatearFecha(hoy),
        'dia': _nombreDia(hoy.weekday),
        'hora': '6:00 AM - 10:00 AM',
        'sector': 'Sector 2',
        'hogares': '11-25',
        'esMiTurno': _sectorSel == 'Sector 2',
      },
      {
        'fecha': _formatearFecha(hoy.add(const Duration(days: 1))),
        'dia': _nombreDia((hoy.weekday % 7) + 1),
        'hora': '10:00 AM - 2:00 PM',
        'sector': 'Sector 3',
        'hogares': '26-40',
        'esMiTurno': _sectorSel == 'Sector 3',
      },
      {
        'fecha': _formatearFecha(hoy.add(const Duration(days: 2))),
        'dia': _nombreDia((hoy.weekday + 1) % 7 + 1),
        'hora': '10:00 AM - 2:00 PM',
        'sector': 'Sector 4',
        'hogares': '41-60',
        'esMiTurno': _sectorSel == 'Sector 4',
      },
    ];
  }

  List<Map<String, dynamic>> get _proximaSemana {
    final hoy = DateTime.now();
    return [
      {
        'fecha': _formatearFecha(hoy.add(const Duration(days: 3))),
        'dia': _nombreDia((hoy.weekday + 2) % 7 + 1),
        'hora': '6:00 AM - 10:00 AM',
        'sector': 'Sector 5',
        'hogares': '61-80',
        'esMiTurno': _sectorSel == 'Sector 5',
      },
      {
        'fecha': _formatearFecha(hoy.add(const Duration(days: 4))),
        'dia': _nombreDia((hoy.weekday + 3) % 7 + 1),
        'hora': '6:00 AM - 10:00 AM',
        'sector': 'Sector 1',
        'hogares': '1-10',
        'esMiTurno': _sectorSel == 'Sector 1',
      },
      {
        'fecha': _formatearFecha(hoy.add(const Duration(days: 5))),
        'dia': _nombreDia((hoy.weekday + 4) % 7 + 1),
        'hora': '6:00 AM - 10:00 AM',
        'sector': 'Sector 2',
        'hogares': '11-25',
        'esMiTurno': _sectorSel == 'Sector 2',
      },
    ];
  }

  String _nombreDia(int weekday) {
    const dias = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    return dias[(weekday - 1) % 7];
  }

  String _formatearFecha(DateTime d) {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${_nombreDia(d.weekday)} ${d.day} ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final rol = AuthService.usuario?.rol ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Calendario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF20C997),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(children: [
        // Filtro sector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.filter_list, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Filtrar por Sector', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sectorSel,
              items: _sectores.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() { _sectorSel = v!; }),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true, fillColor: Colors.white,
              ),
            ),
          ]),
        ),
        // Esta semana
        _seccion('Esta Semana', _semanaActual, true),
        // Próxima semana
        _seccion('Próxima Semana', _proximaSemana, false),
        // Info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F5FF), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF74C0FC)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF1971C2), size: 18),
                SizedBox(width: 6),
                Text('Información del Servicio', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1971C2))),
              ]),
              const SizedBox(height: 8),
              _infoRow('Calendario', 'Semanal — 2 servicios por semana'),
              _infoRow('Duración', '4 horas por sector'),
              _infoRow('Sectores', '5 sectores activos'),
              if (rol == 'Presidente' || rol == 'Operador')
                _infoRow('Hogares', '120 hogares registrados'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _seccion(String titulo, List<Map<String, dynamic>> dias, bool primera) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
      ...dias.map((d) => _tarjetaDia(d)),
    ]);
  }

  Widget _tarjetaDia(Map<String, dynamic> d) {
    final esMiTurno = d['esMiTurno'] as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: esMiTurno
              ? Border.all(color: const Color(0xFF198754), width: 2)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(d['fecha'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            if (esMiTurno)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF198754), borderRadius: BorderRadius.circular(12)),
                child: const Text('MI TURNO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.schedule, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(d['hora'], style: const TextStyle(fontSize: 13, color: Color(0xFF198754), fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('${d['sector']} — Hogares ${d['hogares']}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF1971C2), fontWeight: FontWeight.w600)),
        Text(valor, style: const TextStyle(fontSize: 13, color: Color(0xFF1971C2))),
      ]),
    );
  }
}

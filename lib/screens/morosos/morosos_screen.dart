import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../pagos/pagos_screen.dart';

class MorososScreen extends StatefulWidget {
  const MorososScreen({super.key});
  @override
  State<MorososScreen> createState() => _MorososScreenState();
}

class _MorososScreenState extends State<MorososScreen> {
  List<dynamic> _morosos = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final m = await ApiService.get('/morosos');
      setState(() { _morosos = (m as List).cast<dynamic>(); });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  String _nivelMorosidad(int meses) {
    if (meses >= 3) return 'Crítico';
    if (meses >= 2) return 'Alto';
    return 'Medio';
  }

  Color _colorNivel(int meses) {
    if (meses >= 3) return AppTheme.error;
    if (meses >= 2) return AppTheme.advertencia;
    return Colors.orange.shade300;
  }

  double get _deudaTotal => _morosos.fold(0, (s, m) => s + (m['deuda'] as num).toDouble());
  int get _criticos => _morosos.where((m) => (m['meses'] as int) >= 3).length;
  int get _altos => _morosos.where((m) => (m['meses'] as int) == 2).length;
  int get _medios => _morosos.where((m) => (m['meses'] as int) == 1).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Hogares en Mora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFDC3545),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              // Header resumen
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC3545), Color(0xFFBB2D3B)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(children: [
                  const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                      child: Icon(Icons.warning, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_morosos.length} Hogares en Mora',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Deuda Total: Q ${_deudaTotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),
              // Desglose
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Desglose de Morosidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _desglose('$_criticos', 'Crítico\n(3+ meses)', AppTheme.error),
                      const SizedBox(width: 10),
                      _desglose('$_altos', 'Alto\n(2 meses)', AppTheme.advertencia),
                      const SizedBox(width: 10),
                      _desglose('$_medios', 'Medio\n(1 mes)', Colors.orange.shade300),
                    ]),
                  ]),
                ),
              ),
              // Lista morosos
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Nivel Crítico (3+ meses)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC3545))),
              ),
              ..._morosos.map((m) => _cardMoroso(m)),
              // Acciones masivas
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text('Acciones Masivas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications, size: 16),
                      label: const Text('Recordatorios', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.advertencia,
                        side: const BorderSide(color: AppTheme.advertencia),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _exportarCSV,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Exportar', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primario,
                        side: const BorderSide(color: AppTheme.primario),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ]),
    );
  }

  Widget _desglose(String valor, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: color, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _cardMoroso(Map<String, dynamic> m) {
    final meses = m['meses'] as int;
    final nivel = m['nivel'] ?? _nivelMorosidad(meses);
    final color = _colorNivel(meses);
    final hogarMap = Map<String, dynamic>.from(m);
    hogarMap['id_hogar'] ??= m['id_hogar'];
    hogarMap['numero'] ??= m['numero'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Hogar ${m['numero']} — ${m['nombre']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(nivel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(m['correo'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _datoChip('$meses meses en mora', Icons.calendar_today, color),
            const SizedBox(width: 8),
            _datoChip('Q ${(m['deuda'] as num).toStringAsFixed(2)}', Icons.attach_money, AppTheme.error),
          ]),
          const SizedBox(height: 4),
          Text('Último pago: ${m['ultimoPago']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (m['telefono'] != null) Text('Tel: ${m['telefono']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PagosScreen(hogar: hogarMap))),
              icon: const Icon(Icons.payment, size: 16, color: Colors.white),
              label: const Text('Registrar Pago', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.exito,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: m['telefono'] != null ? () => _hacerLlamada(m['telefono']) : null,
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Llamar', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primario,
                side: const BorderSide(color: AppTheme.primario),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _exportarCSV() {
    List<List<String>> csvData = [
      ['Hogar', 'Nombre', 'Correo', 'Teléfono', 'Meses en Mora', 'Deuda (Q)', 'Último Pago'],
    ];
    for (final m in _morosos) {
      csvData.add([
        m['numero'].toString(),
        m['nombre'].toString(),
        m['correo'] ?? '',
        m['telefono'] ?? '',
        m['meses'].toString(),
        (m['deuda'] as num).toStringAsFixed(2),
        m['ultimoPago'].toString(),
      ]);
    }
    String csv = csvData.map((row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',')).join('\n');
    final bytes = csv.codeUnits;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final link = html.AnchorElement(href: url)
      ..setAttribute('download', 'morosos_${DateTime.now().toIso8601String().substring(0, 10)}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _hacerLlamada(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _datoChip(String texto, IconData icono, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icono, size: 14, color: color),
      const SizedBox(width: 3),
      Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

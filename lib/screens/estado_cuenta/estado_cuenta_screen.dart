import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class EstadoCuentaScreen extends StatefulWidget {
  const EstadoCuentaScreen({super.key});
  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> {
  List<dynamic> _pagos = [];
  bool _cargando = true;
  double _saldoActual = 0;
  double _cuotaMensual = 30.0;
  String _estadoPago = 'Al Día';
  String _ultimoPago = '—';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final usuario = AuthService.usuario;
      if (usuario == null) throw Exception('No hay sesión activa');
      final idHogar = usuario.idUsuario;
      final pagos = await ApiService.get('/pagos') as List;
      final mios = pagos.where((p) => p['id_hogar'] == idHogar).toList();
      double total = 0;
      for (final p in mios) { total += double.tryParse(p['monto'].toString()) ?? 0; }
      String ult = '—';
      if (mios.isNotEmpty) {
        final ultimo = mios.last;
        ult = ultimo['periodo_aplicado']?.toString() ?? '—';
      }
      setState(() {
        _pagos = mios.reversed.toList();
        _saldoActual = 0;
        _estadoPago = 'Al Día';
        _ultimoPago = ult;
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Map<String, List<dynamic>> _agruparPorMes() {
    final map = <String, List<dynamic>>{};
    for (final p in _pagos) {
      final periodo = p['periodo_aplicado']?.toString() ?? 'Sin período';
      map.putIfAbsent(periodo, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    final porMes = _agruparPorMes();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Estado de Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D6EFD),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D6EFD), Color(0xFF6F42C1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 28)),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(usuario?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Comunidad San Miguel', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ]),
                ),
                // Resumen
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Resumen', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Saldo Actual', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('Q ${_saldoActual.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _estadoPago == 'Al Día' ? const Color(0xFFD1E7DD) : const Color(0xFFF8D7DA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            Icon(
                              _estadoPago == 'Al Día' ? Icons.check_circle : Icons.warning,
                              color: _estadoPago == 'Al Día' ? AppTheme.exito : AppTheme.error,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(_estadoPago,
                                style: TextStyle(
                                    color: _estadoPago == 'Al Día' ? AppTheme.exito : AppTheme.error,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ]),
                        ),
                      ]),
                      const Divider(height: 24),
                      Row(children: [
                        Expanded(child: _resumenItem('Cuota Mensual', 'Q ${_cuotaMensual.toStringAsFixed(2)}')),
                        Expanded(child: _resumenItem('Último Pago', _ultimoPago)),
                      ]),
                    ]),
                  ),
                ),
                // Historial
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Historial de Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (porMes.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay pagos registrados', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...porMes.entries.map((entry) => _seccionMes(entry.key, entry.value)),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _resumenItem(String label, String valor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _seccionMes(String mes, List<dynamic> pagos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mes, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        ...pagos.map((p) {
          final monto = double.tryParse(p['monto'].toString()) ?? 0;
          final fecha = p['fecha_pago']?.toString().substring(0, 10) ?? '';
          final metodo = p['metodo_pago']?.toString() ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3)],
            ),
            child: ListTile(
              leading: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD1E7DD),
                  child: Icon(Icons.payment, color: AppTheme.exito, size: 18)),
              title: Text('Pago mensual', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('$fecha de ${DateTime.now().year}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Q ${monto.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.exito)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFD1E7DD), borderRadius: BorderRadius.circular(6)),
                  child: Text(metodo.isEmpty ? 'Pagado' : metodo,
                      style: const TextStyle(color: AppTheme.exito, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

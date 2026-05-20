import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../pagos/pagos_screen.dart';
import '../gastos/gastos_screen.dart';
import '../morosos/morosos_screen.dart';
import '../estado_cuenta/estado_cuenta_screen.dart';
import '../transparencia/transparencia_screen.dart';
import '../notificaciones/notificaciones_screen.dart';

class DashboardTesorero extends StatefulWidget {
  const DashboardTesorero({super.key});
  @override
  State<DashboardTesorero> createState() => _DashboardTesoreroState();
}

class _DashboardTesoreroState extends State<DashboardTesorero> {
  double _recaudado = 0;
  int _pagosAlDia = 0, _morosos = 0;
  double _porCobrar = 0;
  List<dynamic> _ultimosPagos = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final pagos = await ApiService.get('/pagos') as List;
      double total = 0;
      for (final p in pagos) { total += double.tryParse(p['monto'].toString()) ?? 0; }
      setState(() {
        _recaudado = total;
        _pagosAlDia = pagos.length;
        _morosos = 0;
        _porCobrar = 0;
        _ultimosPagos = pagos.reversed.take(3).toList();
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  void _ir(Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    final mes = _mesActual();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Panel Tesorero', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0DCAF0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.cerrarSesion();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(children: [
                // Header gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0DCAF0), Color(0xFF0D6EFD)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                        child: Icon(Icons.account_balance, color: Colors.white, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(usuario?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Gestión Financiera', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  ]),
                ),
                // Financial summary
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Resumen Financiero - $mes',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Q ${_recaudado.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF198754))),
                      const Text('Recaudado este mes', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 14),
                      Row(children: [
                        _miniStat('$_pagosAlDia', 'Pagos al día', const Color(0xFF198754), Icons.check_circle),
                        const SizedBox(width: 10),
                        _miniStat('$_morosos', 'Morosos', const Color(0xFFDC3545), Icons.cancel),
                      ]),
                      if (_porCobrar > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
                            const SizedBox(width: 8),
                            Text('Por cobrar: Q ${_porCobrar.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF856404), fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                ),
                // Últimos pagos
                if (_ultimosPagos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('Últimos Pagos Registrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                      ),
                      child: Column(children: _ultimosPagos.asMap().entries.map((e) {
                        final p = e.value;
                        final monto = double.tryParse(p['monto'].toString()) ?? 0;
                        return Column(children: [
                          ListTile(
                            leading: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD1E7DD),
                                child: Icon(Icons.payment, color: Color(0xFF198754), size: 18)),
                            title: Text('Q ${monto.toStringAsFixed(2)} — ${p['metodo_pago']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Período: ${p['periodo_aplicado']}', style: const TextStyle(fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1E7DD), borderRadius: BorderRadius.circular(8)),
                              child: Text(p['metodo_pago']?.toString() ?? '',
                                  style: const TextStyle(color: Color(0xFF198754), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (e.key < _ultimosPagos.length - 1) const Divider(height: 1, indent: 16),
                        ]);
                      }).toList()),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _accion('Registrar Pago', Icons.payment, const Color(0xFF198754), () => _ir(const PagosScreen())),
                _accion('Hogares en Mora', Icons.warning, const Color(0xFFDC3545), () => _ir(const MorososScreen())),
                _accion('Estado de Cuenta', Icons.account_balance_wallet, const Color(0xFF0D6EFD), () => _ir(const EstadoCuentaScreen())),
                _accion('Reportes Financieros', Icons.bar_chart, const Color(0xFF6F42C1), () => _ir(const TransparenciaScreen())),
                _accion('Gastos', Icons.receipt, const Color(0xFFFD7E14), () => _ir(const GastosScreen())),
                _accion('Notificaciones', Icons.notifications, const Color(0xFF6C757D), () => _ir(const NotificacionesScreen())),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _miniStat(String valor, String label, Color color, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ]),
        ]),
      ),
    );
  }

  Widget _accion(String titulo, IconData icono, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: color, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(icono, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
      ),
    );
  }

  String _mesActual() {
    const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
        'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    final now = DateTime.now();
    return '${meses[now.month - 1]} ${now.year}';
  }
}

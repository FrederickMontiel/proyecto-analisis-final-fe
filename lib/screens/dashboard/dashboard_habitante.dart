import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../nivel_agua/nivel_agua_screen.dart';
import '../incidencias/incidencias_screen.dart';
import '../anuncios/anuncios_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../calendario/calendario_screen.dart';
import '../estado_cuenta/estado_cuenta_screen.dart';

class DashboardHabitante extends StatefulWidget {
  const DashboardHabitante({super.key});
  @override
  State<DashboardHabitante> createState() => _DashboardHabitanteState();
}

class _DashboardHabitanteState extends State<DashboardHabitante> {
  Map<String, dynamic>? _nivelActual;
  int _anunciosNuevos = 0;
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final results = await Future.wait([
        ApiService.get('/niveles'),
        ApiService.get('/anuncios'),
      ]);
      final niveles = results[0] as List;
      final anuncios = results[1] as List;
      if (niveles.isNotEmpty) _nivelActual = niveles.last;
      final hoy = DateTime.now();
      setState(() {
        _anunciosNuevos = anuncios.where((a) {
          final fecha = DateTime.tryParse(a['fecha_publicacion']?.toString() ?? '');
          return fecha != null && hoy.difference(fecha).inHours < 48;
        }).length;
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  void _ir(Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    final p = double.tryParse(_nivelActual?['nivel_porcentaje']?.toString() ?? '0') ?? 0;
    final nivelColor = p <= 20 ? const Color(0xFFDC3545) : p <= 40 ? const Color(0xFFFFC107) : const Color(0xFF198754);
    final nivelLabel = p <= 20 ? 'CRÍTICO' : p <= 40 ? 'ATENCIÓN' : 'BIEN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D6EFD),
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
                      colors: [Color(0xFF0D6EFD), Color(0xFF6F42C1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hola, ${usuario?.nombre ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Row(children: [
                        Icon(Icons.location_on, color: Colors.white70, size: 14),
                        SizedBox(width: 3),
                        Text('Comunidad San Miguel', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ])),
                  ]),
                ),
                // Mi información
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Mi Información', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _infoTile(Icons.check_circle, 'Estado Pago', 'Al Día', const Color(0xFF198754))),
                        const SizedBox(width: 12),
                        Expanded(child: _infoTile(Icons.account_balance_wallet, 'Deuda', 'Q 0.00', const Color(0xFF0D6EFD))),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F1FF), borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Icon(Icons.schedule, color: Color(0xFF0D6EFD), size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Próximo Servicio de Agua',
                                style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Mañana 6:00 AM - 10:00 AM',
                                style: TextStyle(color: Color(0xFF0D6EFD), fontSize: 12)),
                          ])),
                        ]),
                      ),
                    ]),
                  ),
                ),
                // Agua disponible
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _ir(const NivelAguaScreen()),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.water_drop, color: Color(0xFF0D6EFD), size: 20),
                          const SizedBox(width: 6),
                          const Text('Agua Disponible', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: nivelColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text('Estado: $nivelLabel', style: TextStyle(color: nivelColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: p / 100, backgroundColor: Colors.grey.shade200, color: nivelColor, minHeight: 18),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('${p.toStringAsFixed(0)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: nivelColor)),
                          const SizedBox(width: 8),
                          Text('${_nivelActual?['nivel_litros'] ?? 0} litros', style: const TextStyle(color: Colors.grey)),
                        ]),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Acciones Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _accion('Ver Calendario de Distribución', Icons.calendar_month, const Color(0xFF198754), () => _ir(const CalendarioScreen())),
                _accion('Estado de Cuenta', Icons.account_balance_wallet, const Color(0xFF0D6EFD), () => _ir(const EstadoCuentaScreen())),
                _accionConBadge('Anuncios', Icons.announcement, const Color(0xFF6F42C1), _anunciosNuevos, () => _ir(const AnunciosScreen())),
                _accion('Reportar Problema', Icons.report_problem, const Color(0xFFFD7E14), () => _ir(const IncidenciasScreen())),
                _accion('Notificaciones', Icons.notifications, const Color(0xFF6C757D), () => _ir(const NotificacionesScreen())),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _infoTile(IconData icono, String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
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

  Widget _accionConBadge(String titulo, IconData icono, Color color, int badge, VoidCallback onTap) {
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
              if (badge > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge nuevos', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
      ),
    );
  }
}

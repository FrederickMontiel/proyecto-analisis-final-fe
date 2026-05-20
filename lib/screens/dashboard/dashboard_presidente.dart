import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../usuarios/usuarios_screen.dart';
import '../transparencia/transparencia_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../auditoria/auditoria_screen.dart';
import '../parametros/parametros_screen.dart';
import '../analisis/analisis_screen.dart';
import '../nivel_agua/nivel_agua_screen.dart';
import '../anuncios/anuncios_screen.dart';
import '../sectores/gestionar_sectores_screen.dart';
import '../calendario/calendario_screen.dart';

class DashboardPresidente extends StatefulWidget {
  const DashboardPresidente({super.key});
  @override
  State<DashboardPresidente> createState() => _DashboardPresidenteState();
}

class _DashboardPresidenteState extends State<DashboardPresidente> {
  Map<String, dynamic>? _nivelActual;
  int _hogares = 0, _sectores = 0, _alDia = 0, _morosos = 0;
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final results = await Future.wait([
        ApiService.get('/niveles'),
        ApiService.get('/usuarios'),
        ApiService.get('/sectores'),
        ApiService.get('/pagos'),
      ]);
      final niveles = results[0] as List;
      final usuarios = results[1] as List;
      final sectores = results[2] as List;
      if (niveles.isNotEmpty) _nivelActual = niveles.last;
      setState(() {
        _hogares = usuarios.where((u) => u['rol'] == 'Habitante').length;
        _sectores = sectores.length;
        _alDia = usuarios.where((u) => u['estado'] == 'Activo').length;
        _morosos = 0;
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
    final nivelLabel = p <= 20 ? 'Crítico' : p <= 40 ? 'Atención' : 'Normal';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Panel Presidente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
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
                      colors: [Color(0xFFFFC107), Color(0xFFFD7E14)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                        child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(usuario?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Comité del Agua San Miguel', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  ]),
                ),
                // Stats grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                    childAspectRatio: 2.0, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _statCard('$_hogares', 'Hogares', Icons.home, const Color(0xFF0D6EFD)),
                      _statCard('$_sectores', 'Sectores', Icons.map, const Color(0xFF198754)),
                      _statCard('$_alDia', 'Al Día', Icons.check_circle, const Color(0xFF198754)),
                      _statCard('$_morosos', 'Morosos', Icons.warning, const Color(0xFFDC3545)),
                    ],
                  ),
                ),
                // Water level card
                _nivelAguaCard(p, nivelColor, nivelLabel),
                // Acciones
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text('Gestión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _accion('Sectores', Icons.location_on, const Color(0xFF198754), () => _ir(const GestionarSectoresScreen())),
                _accion('Calendario', Icons.calendar_month, const Color(0xFF20C997), () => _ir(const CalendarioScreen())),
                _accion('Anuncios', Icons.campaign, const Color(0xFF0DCAF0), () => _ir(const AnunciosScreen())),
                _accion('Reportes Financieros', Icons.bar_chart, const Color(0xFFFFC107), () => _ir(const TransparenciaScreen())),
                _accion('Usuarios', Icons.people, const Color(0xFF6C757D), () => _ir(const UsuariosScreen())),
                _accion('Notificaciones', Icons.notifications, const Color(0xFF6F42C1), () => _ir(const NotificacionesScreen())),
                _accion('Parámetros', Icons.settings, const Color(0xFF0D6EFD), () => _ir(const ParametrosScreen())),
                _accion('Auditoría', Icons.security, const Color(0xFFDC3545), () => _ir(const AuditoriaScreen())),
                _accion('Análisis Consumo', Icons.analytics, const Color(0xFF6F42C1), () => _ir(const AnalisisConsumoScreen())),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _statCard(String valor, String label, IconData icono, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icono, color: color, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _nivelAguaCard(double p, Color color, String label) {
    return GestureDetector(
      onTap: () => _ir(const NivelAguaScreen()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              const Text('Nivel de Agua', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: p / 100, backgroundColor: Colors.grey.shade200, color: color, minHeight: 18),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text('${p.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Text('${_nivelActual?['nivel_litros'] ?? 0} litros',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _accion(String titulo, IconData icono, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../nivel_agua/nivel_agua_screen.dart';
import '../nivel_agua/registrar_nivel_screen.dart';
import '../lecturas/lecturas_screen.dart';
import '../incidencias/incidencias_screen.dart';
import '../analisis/analisis_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../calendario/calendario_screen.dart';
import '../mantenimientos/mantenimientos_screen.dart';

class DashboardOperador extends StatefulWidget {
  const DashboardOperador({super.key});
  @override
  State<DashboardOperador> createState() => _DashboardOperadorState();
}

class _DashboardOperadorState extends State<DashboardOperador> {
  Map<String, dynamic>? _nivelActual;
  List<dynamic> _incidenciasActivas = [];
  bool _cargando = true;
  String _ultimaActualizacion = '';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; });
    try {
      final results = await Future.wait([
        ApiService.get('/niveles'),
        ApiService.get('/incidencias'),
      ]);
      final niveles = results[0] as List;
      final incidencias = results[1] as List;
      if (niveles.isNotEmpty) {
        _nivelActual = niveles.last;
        final fecha = DateTime.tryParse(_nivelActual!['fecha_registro']?.toString() ?? '');
        if (fecha != null) {
          _ultimaActualizacion = 'Hoy ${fecha.hour.toString().padLeft(2,'0')}:${fecha.minute.toString().padLeft(2,'0')} AM';
        }
      }
      setState(() {
        _incidenciasActivas = incidencias.where((i) =>
            i['estado'] == 'Reportada' || i['estado'] == 'EnRevisión' || i['estado'] == 'EnAtención').toList();
      });
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  void _ir(Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  Color _colorUrgencia(String u) =>
      u == 'Alta' ? AppTheme.error : u == 'Media' ? AppTheme.advertencia : AppTheme.exito;

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    final p = double.tryParse(_nivelActual?['nivel_porcentaje']?.toString() ?? '0') ?? 0;
    final nivelColor = p <= 20 ? AppTheme.error : p <= 40 ? AppTheme.advertencia : AppTheme.exito;
    final nivelLabel = p <= 20 ? 'Crítico' : p <= 40 ? 'Precaución' : 'Normal';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Panel Operador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF198754),
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
                      colors: [Color(0xFF198754), Color(0xFF146C43)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    const CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                        child: Icon(Icons.engineering, color: Colors.white, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(usuario?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Turno: Matutino', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  ]),
                ),
                // Water level card
                Padding(
                  padding: const EdgeInsets.all(16),
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
                        const Text('Nivel de Agua Actual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: nivelColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(nivelLabel, style: TextStyle(color: nivelColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: p / 100, backgroundColor: Colors.grey.shade200, color: nivelColor, minHeight: 18),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('${p.toStringAsFixed(0)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nivelColor)),
                        const SizedBox(width: 8),
                        Text('${_nivelActual?['nivel_litros'] ?? 0} litros',
                            style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ]),
                      if (_ultimaActualizacion.isNotEmpty)
                        Text('Última actualización: $_ultimaActualizacion',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const RegistrarNivelScreen()));
                            if (result == true) _cargar();
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Registrar Nuevo Nivel', style: TextStyle(color: Colors.white, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF198754),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                // Incidencias activas
                if (_incidenciasActivas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(children: [
                      const Text('Incidencias Activas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_incidenciasActivas.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                      ),
                      child: Column(children: _incidenciasActivas.take(3).toList().asMap().entries.map((e) {
                        final inc = e.value;
                        final urgencia = inc['nivel_urgencia']?.toString() ?? 'Media';
                        final colorU = _colorUrgencia(urgencia);
                        final hace = inc['fecha_reporte']?.toString().substring(0, 10) ?? '';
                        return Column(children: [
                          ListTile(
                            leading: CircleAvatar(radius: 18,
                                backgroundColor: colorU.withValues(alpha: 0.12),
                                child: Icon(Icons.warning_amber, color: colorU, size: 18)),
                            title: Text('${inc['tipo_incidencia']} — ${inc['ubicacion'] ?? ''}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(hace, style: const TextStyle(fontSize: 12)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: colorU.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(urgencia, style: TextStyle(color: colorU, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed: () => _ir(const IncidenciasScreen()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D6EFD),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: const Size(0, 28),
                                  side: const BorderSide(color: Color(0xFF0D6EFD)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Atender', style: TextStyle(fontSize: 11)),
                              ),
                            ]),
                          ),
                          if (e.key < (_incidenciasActivas.length < 3 ? _incidenciasActivas.length - 1 : 2))
                            const Divider(height: 1, indent: 16),
                        ]);
                      }).toList()),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _accion('Lecturas de Contadores', Icons.speed, const Color(0xFF0D6EFD), () => _ir(const LecturasScreen())),
                _accion('Calendario', Icons.calendar_month, const Color(0xFF20C997), () => _ir(const CalendarioScreen())),
                _accion('Registrar Mantenimiento', Icons.build, const Color(0xFF6F42C1), () => _ir(const MantenimientosScreen())),
                _accion('Historial de Incidencias', Icons.history, const Color(0xFFFD7E14), () => _ir(const IncidenciasScreen())),
                _accion('Análisis de Consumo', Icons.analytics, const Color(0xFF0DCAF0), () => _ir(const AnalisisConsumoScreen())),
                _accion('Notificaciones', Icons.notifications, const Color(0xFF6C757D), () => _ir(const NotificacionesScreen())),
                const SizedBox(height: 20),
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
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class DashboardPresidente extends StatefulWidget {
  const DashboardPresidente({super.key});
  @override
  State<DashboardPresidente> createState() => _DashboardPresidenteState();
}

class _DashboardPresidenteState extends State<DashboardPresidente> {
  Map<String, dynamic>? _nivelActual;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final niveles = await ApiService.get('/niveles');
      if (niveles != null && (niveles as List).isNotEmpty) {
        setState(() { _nivelActual = niveles.last; });
      }
    } catch (_) {}
    setState(() { _cargando = false; });
  }

  Color _colorNivel(dynamic porcentaje) {
    final p = (porcentaje ?? 100).toDouble();
    if (p <= 20) return AppTheme.error;
    if (p <= 40) return AppTheme.advertencia;
    return AppTheme.exito;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Presidente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.cerrarSesion();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Bienvenido, ${usuario?.nombre ?? ""}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Presidente del Comité', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Nivel de agua
                  if (_nivelActual != null)
                    Card(
                      color: _colorNivel(_nivelActual!['nivel_porcentaje']).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.water, color: _colorNivel(_nivelActual!['nivel_porcentaje']), size: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nivel del Tanque', style: TextStyle(fontSize: 16)),
                                  Text('${_nivelActual!['nivel_porcentaje']}%',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                                          color: _colorNivel(_nivelActual!['nivel_porcentaje']))),
                                  Text('${_nivelActual!['nivel_litros']} litros',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Acciones rápidas
                  const Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _tarjeta('Usuarios', Icons.people, Colors.blue),
                      _tarjeta('Transparencia', Icons.bar_chart, Colors.green),
                      _tarjeta('Notificaciones', Icons.notifications, Colors.orange),
                      _tarjeta('Auditoría', Icons.security, Colors.purple),
                      _tarjeta('Parámetros', Icons.settings, Colors.teal),
                      _tarjeta('Análisis', Icons.analytics, Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tarjeta(String titulo, IconData icono, Color color) => InkWell(
    onTap: () {},
    child: Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 40),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}// Indicador nivel agua en tiempo real con colores semanticos

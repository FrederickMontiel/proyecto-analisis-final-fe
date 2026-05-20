import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../nivel_agua/nivel_agua_screen.dart';
import '../nivel_agua/registrar_nivel_screen.dart';
import '../lecturas/lecturas_screen.dart';
import '../incidencias/incidencias_screen.dart';
import '../analisis/analisis_screen.dart';
import '../notificaciones/notificaciones_screen.dart';

class DashboardOperador extends StatelessWidget {
  const DashboardOperador({super.key});

  void _navegar(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Operador'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bienvenido, ${usuario?.nombre ?? ""}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Operador del Sistema', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _tarjeta(context, 'Registrar Nivel', Icons.water_drop, Colors.blue,
                  () => _navegar(context, const RegistrarNivelScreen())),
              _tarjeta(context, 'Ver Niveles', Icons.show_chart, Colors.cyan,
                  () => _navegar(context, const NivelAguaScreen())),
              _tarjeta(context, 'Lecturas', Icons.speed, Colors.green,
                  () => _navegar(context, const LecturasScreen())),
              _tarjeta(context, 'Incidencias', Icons.warning_amber, Colors.orange,
                  () => _navegar(context, const IncidenciasScreen())),
              _tarjeta(context, 'Análisis', Icons.analytics, Colors.purple,
                  () => _navegar(context, const AnalisisConsumoScreen())),
              _tarjeta(context, 'Notificaciones', Icons.notifications, Colors.teal,
                  () => _navegar(context, const NotificacionesScreen())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(BuildContext context, String titulo, IconData icono, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 40),
            const SizedBox(height: 8),
            Text(titulo,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

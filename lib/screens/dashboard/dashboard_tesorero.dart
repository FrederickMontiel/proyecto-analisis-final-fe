import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../pagos/pagos_screen.dart';
import '../gastos/gastos_screen.dart';
import '../transparencia/transparencia_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../anuncios/anuncios_screen.dart';

class DashboardTesorero extends StatelessWidget {
  const DashboardTesorero({super.key});

  void _navegar(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Tesorero'),
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
          const Text('Tesorero del Comité', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _tarjeta(context, 'Registrar Pago', Icons.payment, Colors.green,
                  () => _navegar(context, const PagosScreen())),
              _tarjeta(context, 'Gastos', Icons.receipt, Colors.orange,
                  () => _navegar(context, const GastosScreen())),
              _tarjeta(context, 'Transparencia', Icons.bar_chart, Colors.purple,
                  () => _navegar(context, const TransparenciaScreen())),
              _tarjeta(context, 'Anuncios', Icons.announcement, Colors.teal,
                  () => _navegar(context, const AnunciosScreen())),
              _tarjeta(context, 'Notificaciones', Icons.notifications, Colors.blue,
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

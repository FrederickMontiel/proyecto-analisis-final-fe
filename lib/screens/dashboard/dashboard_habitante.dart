import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class DashboardHabitante extends StatelessWidget {
  const DashboardHabitante({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await AuthService.cerrarSesion();
            if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hola, ${usuario?.nombre ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Habitante', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _tarjeta('Nivel de Agua', Icons.water_drop, Colors.blue),
              _tarjeta('Mi Cuenta', Icons.account_balance_wallet, Colors.green),
              _tarjeta('Reportar Problema', Icons.report_problem, Colors.orange),
              _tarjeta('Anuncios', Icons.announcement, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(String titulo, IconData icono, Color color) => Card(
    child: InkWell(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 40),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}// Pantalla registro pago: busqueda hogar, metodo, periodo aplicado
// Pantalla anuncios: urgente=rojo, mantenimiento=naranja, informativo=azul

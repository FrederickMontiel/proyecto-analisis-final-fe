import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class DashboardTesorero extends StatelessWidget {
  const DashboardTesorero({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Tesorero'),
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
          Text('Bienvenido, ${usuario?.nombre ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Tesorero del Comité', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _tarjeta('Registrar Pago', Icons.payment, Colors.green),
              _tarjeta('Gastos', Icons.receipt, Colors.orange),
              _tarjeta('Estado de Cuenta', Icons.account_balance_wallet, Colors.blue),
              _tarjeta('Morosos', Icons.warning, Colors.red),
              _tarjeta('Transparencia', Icons.bar_chart, Colors.purple),
              _tarjeta('Reportes', Icons.picture_as_pdf, Colors.teal),
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
}
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class DashboardOperador extends StatelessWidget {
  const DashboardOperador({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Operador'),
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
          const Text('Operador del Sistema', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [
              _tarjeta('Registrar Nivel', Icons.water_drop, Colors.blue),
              _tarjeta('Lecturas Contadores', Icons.speed, Colors.green),
              _tarjeta('Incidencias', Icons.warning_amber, Colors.orange),
              _tarjeta('Mantenimientos', Icons.build, Colors.teal),
              _tarjeta('Análisis Consumo', Icons.analytics, Colors.purple),
              _tarjeta('Sectores', Icons.map, Colors.indigo),
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
}// Dashboard operador: acciones de registrar nivel, lecturas, incidencias

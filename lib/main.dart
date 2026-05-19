import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_presidente.dart';
import 'screens/dashboard/dashboard_tesorero.dart';
import 'screens/dashboard/dashboard_operador.dart';
import 'screens/dashboard/dashboard_habitante.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.cargarSesion();
  runApp(const SistemaAguaApp());
}

class SistemaAguaApp extends StatelessWidget {
  const SistemaAguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Agua San Miguel',
      theme: AppTheme.tema,
      debugShowCheckedModeBanner: false,
      home: _pantallaInicial(),
    );
  }

  Widget _pantallaInicial() {
    if (!AuthService.estaAutenticado || AuthService.usuario == null) {
      return const LoginScreen();
    }
    switch (AuthService.usuario!.rol) {
      case 'Presidente': return const DashboardPresidente();
      case 'Tesorero': return const DashboardTesorero();
      case 'Operador': return const DashboardOperador();
      default: return const DashboardHabitante();
    }
  }
}
// Navegacion por rol correcta al inicio de sesion
// Version 1.0.0 - Sistema Agua San Miguel - Comunidad San Miguel Guatemala

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_presidente.dart';
import '../dashboard/dashboard_tesorero.dart';
import '../dashboard/dashboard_operador.dart';
import '../dashboard/dashboard_habitante.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = null; });

    try {
      final usuario = await AuthService.login(_correoCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;

      Widget destino;
      switch (usuario.rol) {
        case 'Presidente': destino = const DashboardPresidente(); break;
        case 'Tesorero': destino = const DashboardTesorero(); break;
        case 'Operador': destino = const DashboardOperador(); break;
        default: destino = const DashboardHabitante();
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primario,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primario,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sistema de Agua', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('San Miguel', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 28),

                      // Correo
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v!.isEmpty ? 'Ingrese su correo' : null,
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: !_verPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() { _verPassword = !_verPassword; }),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Ingrese su contraseña' : null,
                      ),
                      const SizedBox(height: 8),

                      // Error
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.error),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error))),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Botón
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primario),
                          child: _cargando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Ingresar', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Pantalla login: validacion, carga, redireccion por rol completada

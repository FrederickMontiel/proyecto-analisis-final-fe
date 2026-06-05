class AppConstants {
  static const String apiUrl = 'http://localhost:3000/api';
  // static const String apiUrl = 'https://api.sos.demo.frederickmontiel.com/api';
  static const String tokenKey = 'agua_token';
  static const String usuarioKey = 'agua_usuario';
  static const String appName = 'Sistema Agua San Miguel';

  // Umbrales de nivel
  static const double umbralAlerta = 40.0;
  static const double umbralCritico = 20.0;
  static const double umbralDesperdicio = 30.0;

  // Colores semánticos
  static const int colorNormal = 0xFF28A745;
  static const int colorAlerta = 0xFFFFC107;
  static const int colorCritico = 0xFFDC3545;
  static const int colorPrimario = 0xFF1E6091;
}

// URL API backend NestJS configurada
// Exportacion PDF: reporte consumo y transparencia con paquete pdf

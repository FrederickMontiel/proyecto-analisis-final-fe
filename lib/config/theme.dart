import 'package:flutter/material.dart';

class AppTheme {
  static const Color primario = Color(0xFF1E6091);
  static const Color acento = Color(0xFF2196F3);
  static const Color exito = Color(0xFF28A745);
  static const Color advertencia = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);

  static ThemeData get tema => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primario),
    useMaterial3: true,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      // Textos grandes para baja alfabetización (mínimo 18px)
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 16),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52), // mínimo 44px de altura
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(),
      labelStyle: TextStyle(fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primario,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}
// Tema: 18px minimo texto, 52px botones, colores semanticos accesibles

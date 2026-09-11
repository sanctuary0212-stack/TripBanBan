import 'package:flutter/material.dart';

ThemeData buildTripBanBanTheme() {
  const seed = Color(0xFF119C91);
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5F8F7),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE4ECEA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: seed, width: 1.5)),
    ),
    navigationBarTheme: const NavigationBarThemeData(height: 72, indicatorColor: Color(0xFFD8F1EE)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

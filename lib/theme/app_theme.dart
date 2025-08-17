import 'package:flutter/material.dart';
import 'color.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: kBg,
      colorScheme: base.colorScheme.copyWith(
        primary: kPrimary,
        onPrimary: kOnPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: kTextPrimary,
        displayColor: kTextPrimary,
        fontFamily: 'Roboto',
      ),
      cardTheme: CardThemeData(
        color: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: kTextPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

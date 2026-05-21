import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'System';

  // Font sizes
  static const double xs = 12;
  static const double sm = 14;
  static const double base = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double _2xl = 24;
  static const double _3xl = 30;
  static const double _4xl = 36;
  static const double _5xl = 48;

  // Text styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: _5xl,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: _4xl,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: _3xl,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: _2xl,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: xl,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: lg,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: sm,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: sm,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: xs,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: sm,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: xs,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: xs,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.5,
  );
}

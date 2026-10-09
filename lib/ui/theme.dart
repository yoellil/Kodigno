import 'package:flutter/material.dart';

/// Colors approximated from the reference screenshots; tune by eye.
/// The canvas is white; pastels are for cards and accents only.
class K {
  static const bg = Colors.white;
  static const lavender = Color(0xFFA9A7F2);
  static const yellow = Color(0xFFF7C61C);
  static const pink = Color(0xFFF2A7A5);
  static const mint = Color(0xFFA6E3C3);
  static const blue = Color(0xFF2D4DE8);
  static const ink = Color(0xFF0F0F0F);
  static const tile = Color(0xFFF3F3F6);
  static const line = Color(0xFFE6E6EE);
  static const muted = Color(0xFF6B6B7B);
  static const pastels = [yellow, lavender, pink, mint];
}

/// Heavy, tight display type for titles and big numbers.
TextStyle display(double size, {Color color = K.ink}) => TextStyle(
      fontFamily: 'Bricolage',
      fontSize: size,
      height: 1.0,
      letterSpacing: -size * 0.03,
      fontWeight: FontWeight.w800,
      fontVariations: const [FontVariation('wght', 800)],
      color: color,
    );

TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color color = K.ink}) =>
    TextStyle(
        fontFamily: 'Bricolage', fontSize: size, fontWeight: weight, color: color, height: 1.3);

ThemeData kTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Bricolage',
      scaffoldBackgroundColor: K.bg,
      colorScheme:
          ColorScheme.fromSeed(seedColor: K.lavender, surface: Colors.white).copyWith(primary: K.ink),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      }),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white, indicatorColor: K.yellow, surfaceTintColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: K.tile,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );

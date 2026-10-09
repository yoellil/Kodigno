import 'package:flutter/material.dart';

/// Colors approximated from the reference screenshots; tune by eye.
/// The canvas is white (or near-black in dark mode); pastels are for cards and
/// accents only. Pastels and [ink] never change: text on a pastel is always
/// [ink]. The neutrals below follow [dark], which the app root sets before it
/// builds (and rebuilds everything when it flips).
class K {
  static bool dark = false;

  static const lavender = Color(0xFFA9A7F2);
  static const yellow = Color(0xFFF7C61C);
  static const pink = Color(0xFFF2A7A5);
  static const mint = Color(0xFFA6E3C3);
  static const blue = Color(0xFF2D4DE8);
  static const ink = Color(0xFF0F0F0F);
  static const pastels = [yellow, lavender, pink, mint];

  static Color get bg => dark ? const Color(0xFF121214) : Colors.white;
  static Color get card => dark ? const Color(0xFF1B1B20) : Colors.white;
  static Color get tile => dark ? const Color(0xFF24242B) : const Color(0xFFF3F3F6);
  static Color get line => dark ? const Color(0xFF34343E) : const Color(0xFFE6E6EE);
  static Color get muted => dark ? const Color(0xFFA3A3B5) : const Color(0xFF6B6B7B);

  /// Text, icons and outlines on the canvas.
  static Color get text => dark ? const Color(0xFFF2F2F5) : ink;
}

/// Text and icons on a pastel surface stay dark in dark mode too.
Widget inkOnPastel(Color bg, Widget child) => K.pastels.contains(bg)
    ? DefaultTextStyle.merge(
        style: const TextStyle(color: K.ink),
        child: IconTheme.merge(data: const IconThemeData(color: K.ink), child: child))
    : child;

/// Heavy, tight display type for titles and big numbers.
TextStyle display(double size, {Color? color}) => TextStyle(
      fontFamily: 'Bricolage',
      fontSize: size,
      height: 1.0,
      letterSpacing: -size * 0.03,
      fontWeight: FontWeight.w800,
      fontVariations: const [FontVariation('wght', 800)],
      color: color,
    );

TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
    TextStyle(
        fontFamily: 'Bricolage', fontSize: size, fontWeight: weight, color: color, height: 1.3);

ThemeData kTheme() => ThemeData(
      useMaterial3: true,
      brightness: K.dark ? Brightness.dark : Brightness.light,
      fontFamily: 'Bricolage',
      scaffoldBackgroundColor: K.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: K.lavender,
        brightness: K.dark ? Brightness.dark : Brightness.light,
        surface: K.bg,
      ).copyWith(primary: K.text, onSurface: K.text),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      }),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: K.bg, indicatorColor: K.yellow, surfaceTintColor: K.bg),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: K.tile,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette
  static const bg = Color(0xFF0B0D10);
  static const surface = Color(0xFF11151B);
  static const surface2 = Color(0xFF0F1318);

  static const slate = Color(0xFF2F3A40); // dark slate gray (your UI text/icons)
  static const text = Color(0xFFEAF0F6);  // general body text on dark backgrounds
  static const muted = Color(0xFF7C8A99);

  // Replace the old light-blue accent with white
  static const accent = Colors.white;

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        onSurface: text,
        onPrimary: bg, // if you ever use filled buttons
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),

      // Default icon color (your frosted controls want slate)
      iconTheme: const IconThemeData(color: slate),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // you’re drawing your own frosted bar
        elevation: 0,
        centerTitle: true,
        foregroundColor: text,
      ),

      // Make “standard” Material buttons match the frosted theme when used
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(slate),
          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(slate),
        ),
      ),

      // If you ever use filled buttons, keep them subtle + on-brand
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
          foregroundColor: WidgetStateProperty.all(slate),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),

      // You’re not using BottomNavigationBar anymore, so don’t theme it
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

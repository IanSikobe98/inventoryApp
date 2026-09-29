import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette: shoebox cardboard, leather rust, ledger pine.
class AppColors {
  static const paper = Color(0xFFF1ECE1);
  static const paper2 = Color(0xFFE7DFCE);
  static const card = Color(0xFFFBF8F1);
  static const ink = Color(0xFF201811);
  static const inkSoft = Color(0xFF5B5044);
  static const rust = Color(0xFF9C5630);
  static const rustDark = Color(0xFF7C4324);
  static const rustSoft = Color(0xFFDDBBA5);
  static const pine = Color(0xFF33594B);
  static const pineTint = Color(0xFFD9E4DE);
  static const alert = Color(0xFFA8402E);
  static const alertBg = Color(0xFFF4DED6);
  static const line = Color(0xFFD9CFBA);
  static const placeholder = Color(0xFFB8AC96);
}

/// Text styles. Fraunces for headings/numbers, IBM Plex Sans for UI,
/// IBM Plex Mono for money and codes. Set [useGoogleFonts] to false in tests
/// so nothing tries to download fonts.
class AppText {
  static bool useGoogleFonts = true;

  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.fraunces(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.2);
    }
    return TextStyle(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.2);
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.ibmPlexSans(
          fontSize: size, fontWeight: weight, color: color);
    }
    return TextStyle(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.ibmPlexMono(
          fontSize: size, fontWeight: weight, color: color);
    }
    return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamily: 'monospace');
  }
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.rust,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.rust,
      onPrimary: Colors.white,
      secondary: AppColors.pine,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.alert,
      outline: AppColors.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
    );

    final TextTheme textTheme = AppText.useGoogleFonts
        ? GoogleFonts.ibmPlexSansTextTheme(base.textTheme)
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        : base.textTheme
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.display(size: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.rust, 1.6),
        errorBorder: _border(AppColors.alert),
        focusedErrorBorder: _border(AppColors.alert, 1.6),
        labelStyle: const TextStyle(color: AppColors.inkSoft),
        hintStyle: const TextStyle(color: AppColors.placeholder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.rust,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.rust,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    );
  }
}

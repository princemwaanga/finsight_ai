import 'package:flutter/material.dart';

class AppTheme {
  // Palette
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEFF6FF);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const subtle = Color(0xFFE5E7EB);
  static const bg = Color(0xFFF8FAFF);
  static const surface = Color(0xFFFFFFFF);

  static const Map<String, Color> catColors = {
    'Food & Groceries': Color(0xFF10B981),
    'Transport': Color(0xFF3B82F6),
    'Entertainment': Color(0xFFEC4899),
    'Utilities': Color(0xFFF59E0B),
    'Shopping': Color(0xFF8B5CF6),
    'Healthcare': Color(0xFFEF4444),
    'Education': Color(0xFF06B6D4),
    'Income': Color(0xFF22C55E),
    'Rent & Housing': Color(0xFF92400E),
    'Other': Color(0xFF9CA3AF),
  };

  static Color catColor(String cat) =>
      catColors[cat] ?? const Color(0xFF9CA3AF);

  static final cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static final subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final radiusMd = BorderRadius.circular(12);
  static final radiusLg = BorderRadius.circular(16);
  static final radiusXl = BorderRadius.circular(20);
  static final radiusXxl = BorderRadius.circular(28);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      background: bg,
      surface: surface,
    ),
    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: ink),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radiusLg),
      margin: EdgeInsets.zero,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: subtle,
      selectedColor: primarySoft,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: subtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: subtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: muted, fontSize: 14),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primarySoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: radiusXl),
      elevation: 2,
    ),

    dividerTheme: const DividerThemeData(color: subtle, thickness: 1, space: 0),
  );
}

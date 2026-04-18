import 'package:flutter/material.dart';

/// Teacher-friendly theme: large fonts, high contrast, one-hand usage
class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(brightness: Brightness.light, compact: false);
  }

  static ThemeData get darkTheme {
    return _buildTheme(brightness: Brightness.dark, compact: false);
  }

  static ThemeData lightThemeFor({required bool compact}) {
    return _buildTheme(brightness: Brightness.light, compact: compact);
  }

  static ThemeData darkThemeFor({required bool compact}) {
    return _buildTheme(brightness: Brightness.dark, compact: compact);
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required bool compact,
  }) {
    final isDark = brightness == Brightness.dark;
    final seedColor = isDark
        ? const Color(0xFF42A5F5)
        : const Color(0xFF1565C0);
    final surfaceColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: compact ? 20 : 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontSize: compact ? 18 : 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: compact ? 14 : 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(fontSize: compact ? 14 : 16),
      bodyMedium: TextStyle(fontSize: compact ? 12 : 14),
      labelLarge: TextStyle(
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w600,
      ),
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: seedColor,
        surface: surfaceColor,
      ),
      textTheme: textTheme,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: compact
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: compact ? 48 : 56,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: compact,
        visualDensity: compact
            ? const VisualDensity(horizontal: -2, vertical: -2)
            : VisualDensity.standard,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        minLeadingWidth: compact ? 24 : 32,
        horizontalTitleGap: compact ? 8 : 12,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: compact
              ? const VisualDensity(horizontal: -2, vertical: -2)
              : VisualDensity.standard,
          padding: EdgeInsets.all(compact ? 6 : 8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, compact ? 40 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 10 : 12,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(64, compact ? 40 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 10 : 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, compact ? 40 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 10 : 12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: compact,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 12 : 16,
        ),
      ),
      cardTheme: CardThemeData(margin: EdgeInsets.all(compact ? 6 : 8)),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.bodyMedium,
        labelPadding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      ),
    );

    return baseTheme;
  }
}

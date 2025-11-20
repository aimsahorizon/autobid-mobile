import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: ColorConstants.primary,
        secondary: ColorConstants.secondary,
        surface: ColorConstants.surfaceLight,
        error: ColorConstants.error,
      ),
      scaffoldBackgroundColor: ColorConstants.backgroundLight,
      cardColor: ColorConstants.surfaceLight,
      dividerColor: ColorConstants.textSecondaryLight.withValues(alpha: 0.2),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorConstants.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.textPrimaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: ColorConstants.textSecondaryLight.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimaryLight,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimaryLight,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimaryLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimaryLight,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ColorConstants.textPrimaryLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ColorConstants.textPrimaryLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ColorConstants.textSecondaryLight,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: ColorConstants.textSecondaryLight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorConstants.surfaceLight,
        indicatorColor: ColorConstants.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ColorConstants.primary, size: 28);
          }
          return IconThemeData(
            color: ColorConstants.textSecondaryLight,
            size: 24,
          );
        }),
        // labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        //   if (states.contains(WidgetState.selected)) {
        //     return GoogleFonts.inter(
        //       fontSize: 12,
        //       fontWeight: FontWeight.w600,
        //       color: ColorConstants.primary,
        //     );
        //   }
        //   return GoogleFonts.inter(
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //     color: ColorConstants.textSecondaryLight,
        //   );
        // }),
        elevation: 8,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: ColorConstants.primaryLight,
        secondary: ColorConstants.secondary,
        surface: ColorConstants.surfaceDark,
        error: ColorConstants.error,
      ),
      scaffoldBackgroundColor: ColorConstants.backgroundDark,
      cardColor: ColorConstants.surfaceDark,
      dividerColor: ColorConstants.textSecondaryDark.withValues(alpha: 0.2),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ColorConstants.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorConstants.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.textPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: ColorConstants.textSecondaryDark.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimaryDark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textPrimaryDark,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimaryDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ColorConstants.textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ColorConstants.textPrimaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ColorConstants.textSecondaryDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: ColorConstants.textSecondaryDark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorConstants.surfaceDark,
        indicatorColor: ColorConstants.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ColorConstants.primary, size: 28);
          }
          return IconThemeData(
            color: ColorConstants.textSecondaryDark,
            size: 24,
          );
        }),
        // labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        //   if (states.contains(WidgetState.selected)) {
        //     return GoogleFonts.inter(
        //       fontSize: 12,
        //       fontWeight: FontWeight.w600,
        //       color: ColorConstants.primary,
        //     );
        //   }
        //   return GoogleFonts.inter(
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //     color: ColorConstants.textSecondaryDark,
        //   );
        // }),
        elevation: 8,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

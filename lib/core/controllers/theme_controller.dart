import 'package:flutter/material.dart';

/// Manages app theme mode (light/dark)
/// DEPRECATED: Dark mode is currently disabled. Always returns light mode.
/// To re-enable: uncomment the toggle/set methods and update _themeMode initialization
class ThemeController extends ChangeNotifier {
  // DEPRECATED: Dark mode disabled - always use light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => ThemeMode.light; // Force light mode

  /// Check if current theme is dark
  /// DEPRECATED: Always returns false (light mode only)
  bool get isDarkMode => false; // Always light mode

  /// Toggle between light and dark mode
  /// DEPRECATED: Method disabled - does nothing
  void toggleTheme() {
    // DEPRECATED: Dark mode disabled - this method does nothing
    // Uncomment below to re-enable dark mode:
    // _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    // notifyListeners();
  }

  /// Set specific theme mode
  /// DEPRECATED: Method disabled - does nothing
  void setThemeMode(ThemeMode mode) {
    // DEPRECATED: Dark mode disabled - this method does nothing
    // Uncomment below to re-enable dark mode:
    // _themeMode = mode;
    // notifyListeners();
  }
}

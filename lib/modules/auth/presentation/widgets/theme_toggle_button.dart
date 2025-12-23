import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
      onPressed: onToggle,
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}

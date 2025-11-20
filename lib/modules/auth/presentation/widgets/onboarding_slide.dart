import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';

class OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GradientIconCircle(icon: icon),
        const SizedBox(height: 48),
        Text(
          title,
          style: theme.textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _GradientIconCircle extends StatelessWidget {
  final IconData icon;

  const _GradientIconCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primary,
            ColorConstants.primaryLight,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 70,
        color: Colors.white,
      ),
    );
  }
}

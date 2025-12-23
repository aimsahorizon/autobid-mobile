import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';

class IconHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconBackgroundColor;

  const IconHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: (iconBackgroundColor ?? ColorConstants.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 40,
            color: iconBackgroundColor ?? ColorConstants.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(title, style: theme.textTheme.displayMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

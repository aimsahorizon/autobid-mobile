import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';

/// Reusable progress step widget for transaction progress tracking
/// Shows completion status with icon, title, and subtitle
class ProgressStepWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  const ProgressStepWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Icon circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted
                ? ColorConstants.success
                : (isActive
                    ? ColorConstants.primary
                    : (isDark
                        ? ColorConstants.backgroundDark
                        : ColorConstants.backgroundSecondaryLight)),
            shape: BoxShape.circle,
            border: !isCompleted && !isActive
                ? Border.all(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted || isActive
                ? Colors.white
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight),
          ),
        ),
        const SizedBox(width: 12),
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? null
                      : (isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

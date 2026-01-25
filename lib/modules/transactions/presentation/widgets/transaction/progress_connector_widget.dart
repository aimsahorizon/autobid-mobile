import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

/// Connector line between progress steps
/// Shows visual connection with completion state
class ProgressConnectorWidget extends StatelessWidget {
  final bool isCompleted;

  const ProgressConnectorWidget({
    super.key,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 23, top: 4, bottom: 4),
      width: 2,
      height: 24,
      color: isCompleted
          ? ColorConstants.success
          : (isDark
              ? ColorConstants.textSecondaryDark.withValues(alpha: 0.3)
              : ColorConstants.textSecondaryLight.withValues(alpha: 0.3)),
    );
  }
}

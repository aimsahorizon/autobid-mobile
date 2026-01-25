import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../data/datasources/demo_listing_data.dart';

class DemoAutofillButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DemoAutofillButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!DemoListingData.enableDemoAutofill) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Demo Autofill'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: BorderSide(
            color: ColorConstants.primary.withValues(alpha: 0.5),
          ),
          backgroundColor: isDark
              ? ColorConstants.primary.withValues(alpha: 0.1)
              : ColorConstants.primary.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

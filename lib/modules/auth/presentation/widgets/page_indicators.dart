import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';

class PageIndicators extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicators({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? ColorConstants.primary
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight)
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class OnboardingNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;
    final isFirstPage = currentPage == 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(isLastPage ? 'Get Started' : 'Next'),
          ),
        ),
        if (!isLastPage && !isFirstPage) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../auth_routes.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingController _controller = OnboardingController();

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      icon: Icons.gavel_rounded,
      title: 'Bid with Confidence',
      description:
          'Join live auctions and place bids in real-time with our secure platform',
    ),
    OnboardingContent(
      icon: Icons.trending_up_rounded,
      title: 'Track Your Wins',
      description:
          'Monitor your bids, wins, and auction history all in one place',
    ),
    OnboardingContent(
      icon: Icons.security_rounded,
      title: 'Safe & Secure',
      description: 'Your transactions are protected with bank-level security',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AuthRoutes.login);
                  },
                  child: const Text('Skip'),
                ),
              ),

              // Page view
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return PageView.builder(
                      controller: _controller.pageController,
                      onPageChanged: _controller.setPage,
                      itemCount: _contents.length,
                      itemBuilder: (context, index) {
                        final content = _contents[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
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
                                content.icon,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Title
                            Text(
                              content.title,
                              style: theme.textTheme.displayMedium,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                content.description,
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
                      },
                    );
                  },
                ),
              ),

              // Indicators
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _controller.currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _controller.currentPage == index
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
                },
              ),

              const SizedBox(height: 32),

              // Buttons
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final isLastPage =
                      _controller.currentPage == _contents.length - 1;

                  return Column(
                    children: [
                      // Get Started / Next button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AuthRoutes.login);
                            } else {
                              _controller.nextPage();
                            }
                          },
                          child: Text(isLastPage ? 'Get Started' : 'Next'),
                        ),
                      ),

                      if (!isLastPage) ...[
                        const SizedBox(height: 12),
                        // Back button (only show if not first page)
                        if (_controller.currentPage > 0)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _controller.previousPage,
                              child: const Text('Back'),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingContent {
  final IconData icon;
  final String title;
  final String description;

  OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
  });
}

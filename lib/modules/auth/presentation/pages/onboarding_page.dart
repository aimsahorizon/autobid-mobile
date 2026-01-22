import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/controllers/theme_controller.dart';
import '../../auth_routes.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_indicators.dart';
import '../widgets/onboarding_navigation_buttons.dart';

class OnboardingPage extends StatefulWidget {
  final ThemeController themeController;

  const OnboardingPage({super.key, required this.themeController});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingController _controller = OnboardingController();

  bool _dontShowAgain = false;

  static final List<_OnboardingData> _slides = [
    _OnboardingData(
      icon: Icons.gavel_rounded,
      title: 'Bid with Confidence',
      description:
          'Join live auctions and place bids in real-time with our secure platform',
    ),
    _OnboardingData(
      icon: Icons.trending_up_rounded,
      title: 'Track Your Wins',
      description:
          'Monitor your bids, wins, and auction history all in one place',
    ),
    _OnboardingData(
      icon: Icons.notifications_active_rounded,
      title: 'Stay Updated',
      description:
          'Get real-time notifications for bid updates and auction endings',
    ),
    _OnboardingData(
      icon: Icons.favorite_rounded,
      title: 'Save Your Favorites',
      description:
          'Create lists and save items you love for quick access later',
    ),
    _OnboardingData(
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTopBar(),
              _buildPageView(),
              _buildIndicators(),
              const SizedBox(height: 16),
              _buildDontShowAgainCheckbox(),
              const SizedBox(height: 16),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ListenableBuilder(
          listenable: widget.themeController,
          builder: (context, _) {
            return IconButton(
              icon: Icon(
                widget.themeController.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: widget.themeController.toggleTheme,
            );
          },
        ),
        TextButton(onPressed: _navigateToLogin, child: const Text('Skip')),
      ],
    );
  }

  Widget _buildDontShowAgainCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _dontShowAgain,
          onChanged: (value) {
            setState(() {
              _dontShowAgain = value ?? false;
            });
          },
        ),
        const Text("Don't show this again"),
      ],
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return PageView.builder(
            controller: _controller.pageController,
            onPageChanged: _controller.setPage,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return OnboardingSlide(
                icon: slide.icon,
                title: slide.title,
                description: slide.description,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIndicators() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PageIndicators(
          currentPage: _controller.currentPage,
          pageCount: _slides.length,
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return OnboardingNavigationButtons(
          currentPage: _controller.currentPage,
          totalPages: _slides.length,
          onNext: () {
            if (_controller.currentPage == _slides.length - 1) {
              _navigateToLogin();
            } else {
              _controller.nextPage();
            }
          },
          onBack: _controller.previousPage,
        );
      },
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

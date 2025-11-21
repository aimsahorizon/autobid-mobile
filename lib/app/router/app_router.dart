import 'package:flutter/material.dart';
import '../core/controllers/theme_controller.dart';
import '../presentation/pages/home_page.dart';
import '../../modules/auth/auth_module.dart';
import '../../modules/auth/auth_routes.dart';
import '../../modules/auth/presentation/pages/forgot_password_page.dart';
import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/onboarding_page.dart';
import '../../modules/auth/presentation/pages/registration_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required ThemeController themeController,
  }) {
    switch (settings.name) {
      case '/':
      case AuthRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => OnboardingPage(themeController: themeController),
        );

      case AuthRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            controller: AuthModule.instance.createLoginController(),
            themeController: themeController,
          ),
        );

      case AuthRoutes.registration:
        return MaterialPageRoute(builder: (_) => RegistrationPage());

      case AuthRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => ForgotPasswordPage(
            controller: AuthModule.instance.createForgotPasswordController(),
          ),
        );

      case '/home':
        return MaterialPageRoute(
          builder: (_) => HomePage(themeController: themeController),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

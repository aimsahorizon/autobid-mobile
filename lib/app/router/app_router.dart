import 'package:flutter/material.dart';
import '../../modules/auth/auth_module.dart';
import '../../modules/auth/auth_routes.dart';
import '../../modules/auth/presentation/pages/forgot_password_page.dart';
import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/onboarding_page.dart';
import '../../modules/auth/presentation/pages/registration_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case AuthRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingPage(),
        );

      case AuthRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            controller: AuthModule.instance.createLoginController(),
          ),
        );

      case AuthRoutes.registration:
        return MaterialPageRoute(
          builder: (_) => RegistrationPage(
            controller: AuthModule.instance.createRegistrationController(),
          ),
        );

      case AuthRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => ForgotPasswordPage(
            controller: AuthModule.instance.createForgotPasswordController(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

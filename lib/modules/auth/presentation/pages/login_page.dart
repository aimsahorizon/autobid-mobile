import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/controllers/theme_controller.dart';
import '../../auth_module.dart';
import '../../auth_routes.dart';
import '../../../guest/guest_routes.dart';
import '../controllers/login_controller.dart';
import '../controllers/login_otp_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_loading_button.dart';
import 'login_otp_page.dart';

class LoginPage extends StatefulWidget {
  final LoginController controller;
  final ThemeController themeController;

  const LoginPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final LoginOtpController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = AuthModule.instance.createLoginOtpController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.signIn(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted && success && widget.controller.currentStep == LoginStep.otpVerification) {
        _navigateToOtpPage();
      }
    }
  }

  void _navigateToOtpPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginOtpPage(
          email: widget.controller.userEmail!,
          phoneNumber: widget.controller.userPhoneNumber!,
          otpController: _otpController,
          loginController: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeToggle(),
                const SizedBox(height: 20),
                _buildHeader(theme, isDark),
                const SizedBox(height: 48),
                _buildErrorMessage(),
                _buildUsernameField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildForgotPasswordLink(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 32),
                _buildGuestModeLink(theme, isDark),
                const SizedBox(height: 24),
                _buildSignUpPrompt(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Align(
      alignment: Alignment.topRight,
      child: ListenableBuilder(
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
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue bidding',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.errorMessage != null) {
          return AuthErrorMessage(
            message: widget.controller.errorMessage!,
            onDismiss: widget.controller.clearError,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUsernameField() {
    return AuthTextField(
      controller: _usernameController,
      label: 'Username',
      hint: 'Enter your username',
      prefixIcon: Icons.person_outline,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: widget.controller.obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              widget.controller.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: widget.controller.togglePasswordVisibility,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AuthRoutes.forgotPassword);
        },
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthLoadingButton(
          isLoading: widget.controller.isLoading,
          onPressed: _handleLogin,
          label: 'Sign In',
        );
      },
    );
  }

  Widget _buildGuestModeLink(ThemeData theme, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).pushNamed(GuestRoutes.main);
      },
      icon: const Icon(Icons.preview_rounded),
      label: const Text('Browse as Guest'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AuthRoutes.registration);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

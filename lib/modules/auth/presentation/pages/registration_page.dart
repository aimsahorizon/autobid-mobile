import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/registration_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_loading_button.dart';

class RegistrationPage extends StatefulWidget {
  final RegistrationController controller;

  const RegistrationPage({super.key, required this.controller});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      widget.controller.signUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(theme, isDark),
                const SizedBox(height: 40),
                _buildErrorMessage(),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildUsernameField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),
                _buildSignUpButton(),
                const SizedBox(height: 24),
                _buildTermsText(theme),
                const SizedBox(height: 32),
                _buildSignInPrompt(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Join AutoBid', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Create an account to start bidding',
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

  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      label: 'Email',
      hint: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return AuthTextField(
      controller: _usernameController,
      label: 'Username',
      hint: 'Choose a username',
      prefixIcon: Icons.person_outline,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a username';
        }
        if (value.length < 3) {
          return 'Username must be at least 3 characters';
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
          hint: 'Create a password',
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
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: widget.controller.obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              widget.controller.obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: widget.controller.toggleConfirmPasswordVisibility,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSignUpButton() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthLoadingButton(
          isLoading: widget.controller.isLoading,
          onPressed: _handleSignUp,
          label: 'Create Account',
        );
      },
    );
  }

  Widget _buildTermsText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'By creating an account, you agree to our Terms of Service and Privacy Policy',
        style: theme.textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSignInPrompt(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}

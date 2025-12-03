import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_loading_button.dart';
import '../widgets/otp_input_fields.dart';
import '../widgets/icon_header.dart';

class ForgotPasswordPage extends StatefulWidget {
  final ForgotPasswordController controller;

  const ForgotPasswordPage({super.key, required this.controller});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _usernameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              switch (widget.controller.currentStep) {
                case ForgotPasswordStep.enterUsername:
                  return _UsernameStep(
                    controller: widget.controller,
                    usernameController: _usernameController,
                  );
                case ForgotPasswordStep.verifyOtp:
                  return _OtpStep(
                    controller: widget.controller,
                    otpControllers: _otpControllers,
                    otpFocusNodes: _otpFocusNodes,
                  );
                case ForgotPasswordStep.setNewPassword:
                  return _NewPasswordStep(
                    controller: widget.controller,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                  );
                case ForgotPasswordStep.success:
                  return _SuccessStep(controller: widget.controller);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _UsernameStep extends StatelessWidget {
  final ForgotPasswordController controller;
  final TextEditingController usernameController;

  const _UsernameStep({
    required this.controller,
    required this.usernameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconHeader(
          icon: Icons.lock_reset,
          title: 'Forgot Password?',
          subtitle: 'Enter your username to receive a verification code',
        ),
        const SizedBox(height: 40),
        if (controller.errorMessage != null)
          AuthErrorMessage(
            message: controller.errorMessage!,
            onDismiss: controller.clearError,
          ),
        AuthTextField(
          controller: usernameController,
          label: 'Username',
          hint: 'Enter your username',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 32),
        AuthLoadingButton(
          isLoading: controller.isLoading,
          onPressed: () => controller.sendResetRequest(usernameController.text.trim()),
          label: 'Continue',
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  final ForgotPasswordController controller;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;

  const _OtpStep({
    required this.controller,
    required this.otpControllers,
    required this.otpFocusNodes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconHeader(
          icon: Icons.mail_outline,
          title: 'Verify Code',
          subtitle: 'We sent a 6-digit code to the email associated with ${controller.username}',
        ),
        const SizedBox(height: 40),
        if (controller.errorMessage != null)
          AuthErrorMessage(
            message: controller.errorMessage!,
            onDismiss: controller.clearError,
          ),
        OtpInputFields(
          controllers: otpControllers,
          focusNodes: otpFocusNodes,
          onCompleted: controller.verifyOtp,
          onChanged: controller.clearError,
        ),
        const SizedBox(height: 32),
        AuthLoadingButton(
          isLoading: controller.isLoading,
          onPressed: () {
            final otp = otpControllers.map((c) => c.text).join();
            controller.verifyOtp(otp);
          },
          label: 'Verify',
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: controller.isLoading ? null : controller.resendOtp,
            child: const Text('Resend Code'),
          ),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  final ForgotPasswordController controller;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _NewPasswordStep({
    required this.controller,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconHeader(
          icon: Icons.lock_outline,
          title: 'Create New Password',
          subtitle: 'Enter your new password',
        ),
        const SizedBox(height: 40),
        if (controller.errorMessage != null)
          AuthErrorMessage(
            message: controller.errorMessage!,
            onDismiss: controller.clearError,
          ),
        AuthTextField(
          controller: passwordController,
          label: 'New Password',
          hint: 'Enter new password',
          prefixIcon: Icons.lock_outline,
          obscureText: controller.obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter new password',
          prefixIcon: Icons.lock_outline,
          obscureText: controller.obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: controller.toggleConfirmPasswordVisibility,
          ),
        ),
        const SizedBox(height: 32),
        AuthLoadingButton(
          isLoading: controller.isLoading,
          onPressed: () => controller.resetPassword(
            passwordController.text,
            confirmPasswordController.text,
          ),
          label: 'Reset Password',
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final ForgotPasswordController controller;

  const _SuccessStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ColorConstants.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 60,
            color: ColorConstants.success,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Password Changed!',
          style: theme.textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Your password has been successfully reset. You can now log in with your new password.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              controller.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}

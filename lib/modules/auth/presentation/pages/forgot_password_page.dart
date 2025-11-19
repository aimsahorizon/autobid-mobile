import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  final ForgotPasswordController controller;

  const ForgotPasswordPage({super.key, required this.controller});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _usernameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _usernameController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  return _buildUsernameStep(theme);
                case ForgotPasswordStep.verifyOtp:
                  return _buildOtpStep(theme);
                case ForgotPasswordStep.success:
                  return _buildSuccessStep(theme);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameStep(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ColorConstants.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 40,
            color: ColorConstants.primary,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text('Forgot Password?', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Enter your username to receive a verification code',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),

        const SizedBox(height: 40),

        // Error message
        if (widget.controller.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: ColorConstants.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.controller.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ColorConstants.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Username field
        TextFormField(
          controller: _usernameController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter your username',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),

        const SizedBox(height: 32),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.controller.isLoading
                ? null
                : () {
                    widget.controller.sendResetRequest(
                      _usernameController.text.trim(),
                    );
                  },
            child: widget.controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ColorConstants.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mail_outline,
            size: 40,
            color: ColorConstants.primary,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text('Verify Code', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to ${widget.controller.username}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),

        const SizedBox(height: 40),

        // Error message
        if (widget.controller.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: ColorConstants.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.controller.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ColorConstants.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // OTP fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 50,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: theme.textTheme.headlineMedium,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  widget.controller.clearError();
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }

                  // Auto-verify when all digits are entered
                  if (index == 5 && value.isNotEmpty) {
                    final otp = _otpControllers
                        .map((controller) => controller.text)
                        .join();
                    if (otp.length == 6) {
                      widget.controller.verifyOtp(otp);
                    }
                  }
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.controller.isLoading
                ? null
                : () {
                    final otp = _otpControllers
                        .map((controller) => controller.text)
                        .join();
                    widget.controller.verifyOtp(otp);
                  },
            child: widget.controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify'),
          ),
        ),

        const SizedBox(height: 20),

        // Resend code
        Center(
          child: TextButton(
            onPressed: widget.controller.isLoading
                ? null
                : widget.controller.resendOtp,
            child: const Text('Resend Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 60),

        // Success icon
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

        // Title
        Text(
          'Password Reset Sent!',
          style: theme.textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'We\'ve sent a password reset link to ${widget.controller.username}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 60),

        // Back to login button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.controller.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}

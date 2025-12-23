import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/login_controller.dart';
import '../controllers/login_otp_controller.dart';
import '../widgets/otp_input_fields.dart';

class LoginOtpPage extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final LoginOtpController otpController;
  final LoginController loginController;

  const LoginOtpPage({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.otpController,
    required this.loginController,
  });

  @override
  State<LoginOtpPage> createState() => _LoginOtpPageState();
}

class _LoginOtpPageState extends State<LoginOtpPage> {
  bool _emailOtpSent = false;
  String _emailOtp = '';

  final List<TextEditingController> _emailControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var node in _emailFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    try {
      await widget.otpController.sendEmailOtp(widget.email);
      setState(() {
        _emailOtpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${widget.email}'),
            backgroundColor: ColorConstants.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email OTP: $e'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }


  Future<void> _verifyEmailOtp() async {
    final isVerified = await widget.otpController.verifyEmailOtp(widget.email, _emailOtp);

    if (mounted) {
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: ColorConstants.success,
          ),
        );
        _checkEmailVerified();
        // Reset OTP state after successful verification
        widget.otpController.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }


  void _checkEmailVerified() {
    if (widget.otpController.isEmailVerified) {
      widget.loginController.completeLogin();
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('2-Step Verification'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.loginController.reset();
            widget.otpController.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: ColorConstants.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verify Your Identity',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For your security, please verify your email address to complete login.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              // Email Verification Card
              _buildVerificationCard(
                icon: Icons.email_outlined,
                title: 'Email Verification',
                subtitle: widget.email,
                isVerified: widget.otpController.isEmailVerified,
                isSent: _emailOtpSent,
                controllers: _emailControllers,
                focusNodes: _emailFocusNodes,
                onSend: _sendEmailOtp,
                onVerify: _verifyEmailOtp,
                onOtpChanged: (value) {
                  _emailOtp = value;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    required bool isSent,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required VoidCallback onSend,
    required VoidCallback onVerify,
    required ValueChanged<String> onOtpChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? ColorConstants.success
              : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          width: isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle_rounded : icon,
                color: isVerified ? ColorConstants.success : ColorConstants.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorConstants.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: ColorConstants.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 20),
            if (!isSent) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send OTP'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              OtpInputFields(
                controllers: controllers,
                focusNodes: focusNodes,
                onCompleted: onOtpChanged,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.otpController.isLoading ? null : onVerify,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: widget.otpController.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify OTP'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: onSend,
                  child: const Text('Resend OTP'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

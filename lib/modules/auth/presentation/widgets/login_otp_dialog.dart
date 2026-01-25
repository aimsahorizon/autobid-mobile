import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/login_otp_controller.dart';
import 'otp_input_fields.dart';

class LoginOtpDialog extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final LoginOtpController controller;
  final VoidCallback onComplete;

  const LoginOtpDialog({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.controller,
    required this.onComplete,
  });

  @override
  State<LoginOtpDialog> createState() => _LoginOtpDialogState();
}

class _LoginOtpDialogState extends State<LoginOtpDialog> {
  bool _emailOtpSent = false;
  bool _phoneOtpSent = false;
  String _emailOtp = '';
  String _phoneOtp = '';

  final List<TextEditingController> _emailControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());

  final List<TextEditingController> _phoneControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _phoneFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var node in _emailFocusNodes) {
      node.dispose();
    }
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var node in _phoneFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    try {
      await widget.controller.sendEmailOtp(widget.email);
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

  Future<void> _sendPhoneOtp() async {
    try {
      await widget.controller.sendPhoneOtp(widget.phoneNumber);
      setState(() {
        _phoneOtpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to +63${widget.phoneNumber}'),
            backgroundColor: ColorConstants.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send phone OTP: $e'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    final isVerified = await widget.controller.verifyEmailOtp(widget.email, _emailOtp);

    if (mounted) {
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: ColorConstants.success,
          ),
        );
        _checkBothVerified();
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

  Future<void> _verifyPhoneOtp() async {
    final isVerified = await widget.controller.verifyPhoneOtp(widget.phoneNumber, _phoneOtp);

    if (mounted) {
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified successfully!'),
            backgroundColor: ColorConstants.success,
          ),
        );
        _checkBothVerified();
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

  void _checkBothVerified() {
    if (widget.controller.isBothVerified) {
      Navigator.pop(context);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: ColorConstants.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '2-Step Verification',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your email and phone number to complete login',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              _buildVerificationCard(
                icon: Icons.email_outlined,
                title: 'Email Verification',
                subtitle: widget.email,
                isVerified: widget.controller.isEmailVerified,
                isSent: _emailOtpSent,
                controllers: _emailControllers,
                focusNodes: _emailFocusNodes,
                onSend: _sendEmailOtp,
                onVerify: _verifyEmailOtp,
                onOtpChanged: (value) {
                  _emailOtp = value;
                },
              ),
              const SizedBox(height: 16),
              _buildVerificationCard(
                icon: Icons.phone_android_rounded,
                title: 'Phone Verification',
                subtitle: '+63${widget.phoneNumber}',
                isVerified: widget.controller.isPhoneVerified,
                isSent: _phoneOtpSent,
                controllers: _phoneControllers,
                focusNodes: _phoneFocusNodes,
                onSend: _sendPhoneOtp,
                onVerify: _verifyPhoneOtp,
                onOtpChanged: (value) {
                  _phoneOtp = value;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ColorConstants.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            if (!isSent) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send OTP'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              OtpInputFields(
                controllers: controllers,
                focusNodes: focusNodes,
                onCompleted: onOtpChanged,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.controller.isLoading ? null : onVerify,
                  child: widget.controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 8),
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

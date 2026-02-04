import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../otp_input_fields.dart';

class OtpVerificationStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const OtpVerificationStep({super.key, required this.controller});

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep> {
  bool _isVerifyingEmail = false;
  bool _emailSent = false;
  String _emailOtp = '';
  
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  final List<TextEditingController> _phoneControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _phoneFocusNodes = List.generate(6, (_) => FocusNode());

  final List<TextEditingController> _emailControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var node in _phoneFocusNodes) {
      node.dispose();
    }
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var node in _emailFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendEmailOtp() async {
    try {
      await widget.controller.sendEmailOtp();

      setState(() {
        _emailSent = true;
      });
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${widget.controller.email ?? ''}'),
            backgroundColor: ColorConstants.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      final isVerified = await widget.controller.verifyEmailOtp(_emailOtp);

      if (mounted) {
        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: ColorConstants.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP. Please try again.'),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: ColorConstants.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your email address',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          _buildVerificationCard(
            icon: Icons.email_outlined,
            title: 'Email Verification',
            subtitle: widget.controller.email ?? '',
            isVerified: widget.controller.emailOtpVerified,
            isSent: _emailSent,
            isVerifying: _isVerifyingEmail,
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
    );
  }

  Widget _buildVerificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    required bool isSent,
    required bool isVerifying,
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
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? ColorConstants.success
              : (isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight),
          width: isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (isVerified
                              ? ColorConstants.success
                              : ColorConstants.primary)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified ? Icons.check_circle_rounded : icon,
                  color: isVerified
                      ? ColorConstants.success
                      : ColorConstants.primary,
                  size: 24,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 20),
            if (!isSent) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send OTP'),
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
                  onPressed: isVerifying ? null : onVerify,
                  child: isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _resendCountdown > 0 ? null : onSend,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend OTP (${_resendCountdown}s)'
                        : 'Resend OTP',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

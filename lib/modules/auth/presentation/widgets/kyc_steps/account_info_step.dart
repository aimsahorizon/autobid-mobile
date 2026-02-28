import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../../profile/presentation/pages/legal_page.dart';
import '../../controllers/kyc_registration_controller.dart';

class AccountInfoStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const AccountInfoStep({super.key, required this.controller});

  @override
  State<AccountInfoStep> createState() => _AccountInfoStepState();
}

class _AccountInfoStepState extends State<AccountInfoStep> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingUsername = false;
  Timer? _emailDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.controller.username != null) {
      _usernameController.text = widget.controller.username!;
    }
    if (widget.controller.email != null) {
      _emailController.text = widget.controller.email!;
    }
    if (widget.controller.password != null) {
      _passwordController.text = widget.controller.password!;
    }
    if (widget.controller.confirmPassword != null) {
      _confirmPasswordController.text = widget.controller.confirmPassword!;
    }

    _usernameController.addListener(() {
      widget.controller.setUsername(_usernameController.text);
      _checkUsernameAvailability();
    });
    _emailController.addListener(() {
      widget.controller.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      widget.controller.setPassword(_passwordController.text);
      if (mounted) setState(() {});
    });
    _confirmPasswordController.addListener(() {
      widget.controller.setConfirmPassword(_confirmPasswordController.text);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailDebounce?.cancel();
    super.dispose();
  }

  // Check username availability in database
  void _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();

    // Only check if username has at least 3 characters
    if (username.length < 3) {
      // Clear status in controller logic is handled by setting text
      return;
    }

    setState(() => _isCheckingUsername = true);
    await widget.controller.checkUsernameAvailability(username);
    if (mounted) setState(() => _isCheckingUsername = false);
  }

  // Check email availability in database
  void _checkEmailAvailability() {
    if (_emailDebounce?.isActive ?? false) _emailDebounce!.cancel();

    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email)) {
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 800), () async {
      await widget.controller.checkEmailAvailability(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isUsernameAvailable = widget.controller.isUsernameAvailable;
        final isEmailAvailable = widget.controller.isEmailAvailable;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Information',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account credentials',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Choose a unique username',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : isUsernameAvailable == null
                      ? null
                      : Icon(
                          isUsernameAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isUsernameAvailable
                              ? ColorConstants.success
                              : ColorConstants.error,
                        ),
                  helperText: isUsernameAvailable == false
                      ? 'Username is already taken or invalid'
                      : isUsernameAvailable == true
                      ? 'Username is available'
                      : null,
                  helperStyle: TextStyle(
                    color: isUsernameAvailable == false
                        ? ColorConstants.error
                        : ColorConstants.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _checkEmailAvailability(),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: isEmailAvailable == null
                      ? null
                      : Icon(
                          isEmailAvailable ? Icons.check_circle : Icons.cancel,
                          color: isEmailAvailable
                              ? ColorConstants.success
                              : ColorConstants.error,
                        ),
                  helperText: isEmailAvailable == false
                      ? 'Email is already registered'
                      : null,
                  helperStyle: TextStyle(color: ColorConstants.error),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a strong password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.controller.passwordStrength,
                          backgroundColor: (isDark
                              ? Colors.grey[800]
                              : Colors.grey[200]),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.controller.passwordStrengthColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.controller.passwordStrengthText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.controller.passwordStrengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_confirmPasswordController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty)
                        Icon(
                          _passwordController.text ==
                                  _confirmPasswordController.text
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              _passwordController.text ==
                                  _confirmPasswordController.text
                              ? ColorConstants.success
                              : ColorConstants.error,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ],
                  ),
                  helperText:
                      _confirmPasswordController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty &&
                          _passwordController.text !=
                              _confirmPasswordController.text
                      ? 'Passwords do not match'
                      : null,
                  helperStyle: const TextStyle(color: ColorConstants.error),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: widget.controller.termsAccepted,
                onChanged: (value) {
                  widget.controller.setTermsAccepted(value ?? false);
                  // No local setState needed as ListenableBuilder handles rebuild
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Text('I agree to the '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalPage(
                              title: 'Terms & Conditions',
                              type: 'terms',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: ColorConstants.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: widget.controller.privacyAccepted,
                onChanged: (value) {
                  widget.controller.setPrivacyAccepted(value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Text('I agree to the '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalPage(
                              title: 'Privacy Policy',
                              type: 'privacy',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: ColorConstants.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstants.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: ColorConstants.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Password Requirements',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: ColorConstants.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRequirement(
                      'At least 8 characters',
                      widget.controller.hasMinLength,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement(
                      'At least one uppercase letter',
                      widget.controller.hasUppercase,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement(
                      'At least one lowercase letter',
                      widget.controller.hasLowercase,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement(
                      'At least one number',
                      widget.controller.hasDigits,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement(
                      'At least one special character',
                      widget.controller.hasSpecialCharacters,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? ColorConstants.success : ColorConstants.info,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isMet ? ColorConstants.success : ColorConstants.info,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';

class AccountInfoStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const AccountInfoStep({
    super.key,
    required this.controller,
  });

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
  bool? _isUsernameAvailable;

  @override
  void initState() {
    super.initState();
    if (widget.controller.username != null) {
      _usernameController.text = widget.controller.username!;
    }
    if (widget.controller.email != null) {
      _emailController.text = widget.controller.email!;
    }
    if (widget.controller.phoneNumber != null) {
      _phoneController.text = widget.controller.phoneNumber!;
    }
    if (widget.controller.password != null) {
      _passwordController.text = widget.controller.password!;
      _confirmPasswordController.text = widget.controller.password!;
    }

    _usernameController.addListener(() {
      widget.controller.setUsername(_usernameController.text);
      _checkUsernameAvailability();
    });
    _emailController.addListener(() {
      widget.controller.setEmail(_emailController.text);
    });
    _phoneController.addListener(() {
      widget.controller.setPhoneNumber(_phoneController.text);
    });
    _passwordController.addListener(() {
      widget.controller.setPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Check username availability in database
  void _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();

    // Only check if username has at least 3 characters
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    // TODO: Call checkUsernameAvailable usecase
    // For now, simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isCheckingUsername = false;
      // Mock: username available if doesn't contain 'admin' or 'test'
      _isUsernameAvailable = !username.contains('admin') && !username.contains('test');
    });
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
                  : _isUsernameAvailable == null
                      ? null
                      : Icon(
                          _isUsernameAvailable!
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _isUsernameAvailable!
                              ? ColorConstants.success
                              : ColorConstants.error,
                        ),
              helperText: _isUsernameAvailable == false
                  ? 'Username is already taken'
                  : _isUsernameAvailable == true
                      ? 'Username is available'
                      : null,
              helperStyle: TextStyle(
                color: _isUsernameAvailable == false
                    ? ColorConstants.error
                    : ColorConstants.success,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'your.email@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '9XX XXX XXXX',
              prefixIcon: Icon(Icons.phone_outlined),
              prefixText: '+63 ',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
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
            ),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: widget.controller.termsAccepted,
            onChanged: (value) {
              widget.controller.setTermsAccepted(value ?? false);
              setState(() {});
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('I agree to the '),
                GestureDetector(
                  onTap: () {
                    // Show terms & conditions
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
              setState(() {});
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('I agree to the '),
                GestureDetector(
                  onTap: () {
                    // Show privacy policy
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
                _buildRequirement('At least 8 characters'),
                const SizedBox(height: 4),
                _buildRequirement('At least one uppercase letter'),
                const SizedBox(height: 4),
                _buildRequirement('At least one lowercase letter'),
                const SizedBox(height: 4),
                _buildRequirement('At least one number'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: ColorConstants.info,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorConstants.info,
              ),
        ),
      ],
    );
  }
}

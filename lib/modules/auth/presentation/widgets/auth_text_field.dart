import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Disable autocorrect and capitalization for username fields
    final isUsernameField = keyboardType == TextInputType.text &&
                            !obscureText &&
                            (label.toLowerCase().contains('username') ||
                             hint.toLowerCase().contains('username'));

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: isUsernameField ? false : true,
      enableSuggestions: isUsernameField ? false : true,
      textCapitalization: isUsernameField ? TextCapitalization.none : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

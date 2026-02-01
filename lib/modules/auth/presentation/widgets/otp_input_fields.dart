import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Function(String) onCompleted;
  final VoidCallback? onChanged;

  const OtpInputFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 50,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
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
              onChanged?.call();
              if (value.isNotEmpty && index < 5) {
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }

              if (index == 5 && value.isNotEmpty) {
                final otp = controllers.map((c) => c.text).join();
                if (otp.length == 6) {
                  onCompleted(otp);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

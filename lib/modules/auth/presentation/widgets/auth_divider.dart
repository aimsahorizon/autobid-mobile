import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({super.key, this.text = 'OR'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }
}

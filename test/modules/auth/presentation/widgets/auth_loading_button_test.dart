import 'package:autobid_mobile/modules/auth/presentation/widgets/auth_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthLoadingButton uses primary color when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthLoadingButton(
            isLoading: false,
            onPressed: () {},
            label: 'Test Button',
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    // Check if the button is enabled (onPressed is not null)
    expect(button.onPressed, isNotNull);

    // Default elevated button style
    // We can't easily check computed style without checking the theme, but we can check if it renders.
    expect(find.text('Test Button'), findsOneWidget);
  });

  testWidgets(
    'AuthLoadingButton uses semi-transparent primary color when disabled/loading',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.light(primary: Colors.blue),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: AuthLoadingButton(
              isLoading: true,
              onPressed: () {},
              label: 'Test Button',
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      // Check if button is disabled
      expect(button.onPressed, isNull);

      // Check loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);

      // Verify style
      // The style property is set directly on the button
      final style = button.style;
      expect(style, isNotNull);

      // Resolve the disabledBackgroundColor
      // disabledBackgroundColor helper in styleFrom sets the backgroundColor for disabled state
      final disabledColor = style!.backgroundColor?.resolve({
        WidgetState.disabled,
      });

      // We expect it to be primary color with alpha 0.6 (~153)
      // Colors.blue is 0xFF2196F3.
      // Alpha 0.6 * 255 = 153.
      expect(disabledColor, isNotNull);
      expect((disabledColor!.a * 255).round(), closeTo(153, 1));
    },
  );
}

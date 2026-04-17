import 'package:flutter/services.dart';

/// Formats numeric input with thousands commas as the user types.
/// Integer mode: digits only, formatted with commas (e.g., 1,000,000).
/// Decimal mode: digits + one decimal point, integer part formatted with commas.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final bool allowDecimal;

  const ThousandsSeparatorInputFormatter({this.allowDecimal = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip all commas
    String raw = newValue.text.replaceAll(',', '');

    String intPart;
    String decPart = '';

    if (allowDecimal && raw.contains('.')) {
      final dotIndex = raw.indexOf('.');
      intPart = raw.substring(0, dotIndex);
      // Only allow digits after decimal, cap at 2 decimal places
      final afterDot = raw
          .substring(dotIndex + 1)
          .replaceAll(RegExp(r'[^\d]'), '');
      decPart = '.${afterDot.length > 2 ? afterDot.substring(0, 2) : afterDot}';
    } else {
      intPart = raw;
    }

    // Remove non-digits from intPart
    intPart = intPart.replaceAll(RegExp(r'[^\d]'), '');

    if (intPart.isEmpty && decPart.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format integer part with commas
    final formatted = _addCommas(intPart) + decPart;

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addCommas(String digits) {
    if (digits.isEmpty) return '';
    final result = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(digits[i]);
    }
    return result.toString();
  }

  /// Format a double value with commas for display in a TextEditingController.
  static String formatDouble(double? value) {
    if (value == null) return '';
    if (value == value.truncateToDouble()) {
      return _addCommas(value.toInt().toString());
    }
    final parts = value.toString().split('.');
    return _addCommas(parts[0]) + '.' + parts[1];
  }

  /// Format an int value with commas for display in a TextEditingController.
  static String formatInt(int? value) {
    if (value == null) return '';
    return _addCommas(value.toString());
  }

  /// Strip commas and parse as double.
  static double? parseDouble(String? text) {
    if (text == null || text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', ''));
  }

  /// Strip commas and parse as int.
  static int? parseInt(String? text) {
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text.replaceAll(',', ''));
  }
}

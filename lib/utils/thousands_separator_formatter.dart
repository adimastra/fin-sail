import 'package:flutter/services.dart';

/// Formats numeric input with dot '.' thousand separators (e.g., 999.999.999)
/// while maintaining correct cursor position when inserting or deleting digits.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Determine how many digits are before the cursor in newValue
    final cursorPosition = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPosition && i < newValue.text.length; i++) {
      if (_isDigit(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Extract digits only
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Remove leading zeros if number > 0
    String cleanedDigits = digitsOnly;
    if (cleanedDigits.length > 1 && cleanedDigits.startsWith('0')) {
      cleanedDigits = cleanedDigits.replaceFirst(RegExp(r'^0+'), '');
      if (cleanedDigits.isEmpty) cleanedDigits = '0';
    }

    // Format with dots as thousands separator (999.999.999)
    final formatted = _formatWithDots(cleanedDigits);

    // Calculate new cursor offset matching digitsBeforeCursor
    int newCursorOffset = 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted[i])) {
        digitsSeen++;
      }
      if (digitsSeen == digitsBeforeCursor) {
        newCursorOffset = i + 1;
        break;
      }
    }
    if (digitsBeforeCursor == 0) {
      newCursorOffset = 0;
    } else if (digitsSeen < digitsBeforeCursor) {
      newCursorOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  static bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0'..'9'
  }

  static String _formatWithDots(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Formats a number to dot-separated thousands string, e.g. 125000 -> "125.000"
  static String format(num amount) {
    final intVal = amount.round();
    return _formatWithDots(intVal.abs().toString());
  }

  /// Parses dot-separated text string to double, e.g. "125.000" -> 125000.0
  static double parse(String text) {
    final clean = text.replaceAll('.', '').replaceAll(RegExp(r'[^\d]'), '').trim();
    return double.tryParse(clean) ?? 0.0;
  }
}

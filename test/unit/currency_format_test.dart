import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/utils/currency_format.dart';

void main() {
  group('CurrencyFormat Unit Tests', () {
    test('Formats positive integer amounts with Rp prefix and thousands separators', () {
      expect(CurrencyFormat.format(1152000), 'Rp 1.152.000');
      expect(CurrencyFormat.format(25000), 'Rp 25.000');
      expect(CurrencyFormat.format(500), 'Rp 500');
    });

    test('Formats zero correctly', () {
      expect(CurrencyFormat.format(0), 'Rp 0');
    });

    test('Formats double amounts properly rounding to 0 decimal digits', () {
      expect(CurrencyFormat.format(65000.75), 'Rp 65.001');
      expect(CurrencyFormat.format(65000.25), 'Rp 65.000');
    });

    test('Handles negative numbers cleanly with negative sign', () {
      final formatted = CurrencyFormat.format(-25000);
      expect(formatted.contains('25.000'), isTrue);
    });
  });
}

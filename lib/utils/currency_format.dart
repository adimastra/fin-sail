import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(num amount) {
    // Standard Indonesian Rupiah format: Rp1.350.000 or Rp 1.350.000
    final formatted = _idrFormatter.format(amount);
    // Ensure space between Rp and the digits for clean presentation: Rp 1.350.000
    if (formatted.startsWith('Rp') && !formatted.startsWith('Rp ')) {
      return formatted.replaceFirst('Rp', 'Rp ');
    }
    return formatted;
  }
}

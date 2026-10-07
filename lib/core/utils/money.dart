/// Display scale for stored amounts. TND uses three decimals. Other
/// supported currencies use two. Extra digits are rejected by validation
/// later; this helper only formats.
abstract final class Money {
  static int decimalScale(String currencyCode) {
    return currencyCode == 'TND' ? 3 : 2;
  }

  static String format(double amount, String currencyCode) {
    return amount.toStringAsFixed(decimalScale(currencyCode));
  }
}

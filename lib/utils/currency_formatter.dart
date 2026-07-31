class CurrencyFormatter {
  static String format(double price) {
    final int val = price.round();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '৳$formatted';
  }
}

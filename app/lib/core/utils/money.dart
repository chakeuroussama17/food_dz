/// Formats whole Algerian dinars, e.g. 1250 -> "1 250 DA" / "1 250 دج".
String formatDzd(int amount, String languageCode) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' '); // narrow nbsp
    buf.write(digits[i]);
  }
  final unit = languageCode == 'ar' ? 'دج' : 'DA';
  return '${negative ? '-' : ''}$buf $unit';
}

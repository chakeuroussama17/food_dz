/// Normalises an Algerian mobile number to the local 10-digit form
/// (05xxxxxxxx, 06xxxxxxxx, 07xxxxxxxx). Accepts +213 / 00213 prefixes,
/// spaces, dots and dashes. Returns null if invalid.
String? normalizeDzPhone(String input) {
  var s = input.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (s.startsWith('+213')) {
    s = '0${s.substring(4)}';
  } else if (s.startsWith('00213')) {
    s = '0${s.substring(5)}';
  } else if (s.startsWith('213') && s.length == 12) {
    s = '0${s.substring(3)}';
  }
  return RegExp(r'^0[567][0-9]{8}$').hasMatch(s) ? s : null;
}

bool isValidName(String s) {
  final t = s.trim();
  return t.length >= 2 && t.length <= 80;
}

/// Pragmatic email check: something@something.tld, no spaces, max 254.
bool isValidEmail(String s) {
  final t = s.trim();
  return t.length <= 254 &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(t);
}

/// Same minimum as the Supabase config (auth.password.min_length = 8).
bool isValidPassword(String s) => s.length >= 8 && s.length <= 72;

/// Restaurant numbers may be landlines (02x, 03x, 04x) or mobiles.
/// Returns the 9- or 10-digit local form, or null if invalid.
String? normalizeRestaurantPhone(String input) {
  final mobile = normalizeDzPhone(input);
  if (mobile != null) return mobile;
  var s = input.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (s.startsWith('+213')) s = '0${s.substring(4)}';
  if (s.startsWith('00213')) s = '0${s.substring(5)}';
  return RegExp(r'^0[2-7][0-9]{7,8}$').hasMatch(s) ? s : null;
}

import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/app_localizations.dart';

/// "Opens today at 18:00" / "Opens tomorrow at 11:00" / "Opens Friday at
/// 12:00"; without a known time: the plain "closed" note.
String closedText(AppLocalizations l, String lang, DateTime? next) {
  if (next == null) return l.restaurantClosedNote;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(next.year, next.month, next.day);
  final time = DateFormat('HH:mm').format(next);
  final diff = day.difference(today).inDays;
  if (diff <= 0) return l.opensTodayAt(time);
  if (diff == 1) return l.opensTomorrowAt(time);
  return l.opensOnAt(DateFormat.EEEE(lang).format(next), time);
}

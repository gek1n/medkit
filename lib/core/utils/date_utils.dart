import 'package:flutter/widgets.dart' show BuildContext, Localizations;
import 'package:intl/intl.dart';

import 'l10n_ext.dart';

abstract final class MKDateUtils {
  static String formatDayHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return context.l10n.dayToday;
    if (diff == 1) return context.l10n.dayTomorrow;
    if (diff == -1) return context.l10n.dayYesterday;
    return DateFormat('d MMMM', Localizations.localeOf(context).languageCode).format(date);
  }

  static String formatTime(DateTime time) => DateFormat('HH:mm').format(time);
  static String formatDate(BuildContext context, DateTime date) =>
      DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(date);
  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
}

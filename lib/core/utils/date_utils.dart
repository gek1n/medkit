import 'package:intl/intl.dart';

abstract final class MKDateUtils {
  static String formatDate(DateTime dt, {String locale = 'uk'}) =>
      DateFormat('d MMMM', locale).format(dt);

  static String formatDayName(DateTime dt, {String locale = 'uk'}) {
    final s = DateFormat('EEEE', locale).format(dt);
    return s[0].toUpperCase() + s.substring(1);
  }

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

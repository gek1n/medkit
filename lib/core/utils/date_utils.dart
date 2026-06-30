import 'package:intl/intl.dart';

abstract final class MKDateUtils {
  static String formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Сьогодні';
    if (diff == 1) return 'Завтра';
    if (diff == -1) return 'Вчора';
    return DateFormat('d MMMM', 'uk').format(date);
  }

  static String formatTime(DateTime time) => DateFormat('HH:mm').format(time);
  static String formatDate(DateTime date) => DateFormat('d MMM yyyy', 'uk').format(date);
  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
}

import 'package:intl/intl.dart';

class PeriodHelper {
  static DateTime getPeriodStart(int payDay, {DateTime? now}) {
    now ??= DateTime.now();
    final thisMonthPayDay = _clampDay(now.year, now.month, payDay);
    if (now.isAfter(thisMonthPayDay) || now.isAtSameMomentAs(thisMonthPayDay)) {
      return thisMonthPayDay;
    }
    return _clampDay(now.year, now.month - 1, payDay);
  }

  static DateTime getPeriodEnd(int payDay, {DateTime? now}) {
    final start = getPeriodStart(payDay, now: now);
    final nextPayDay = _clampDay(start.year, start.month + 1, payDay);
    return nextPayDay.subtract(const Duration(days: 1));
  }

  static String formatPeriodRange(int payDay, {DateTime? now}) {
    now ??= DateTime.now();
    final start = getPeriodStart(payDay, now: now);
    final end = getPeriodEnd(payDay, now: now);
    final fmt = DateFormat('d MMM');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  static bool isInPeriod(DateTime date, int payDay, {DateTime? now}) {
    now ??= DateTime.now();
    final start = getPeriodStart(payDay, now: now);
    final end = getPeriodEnd(payDay, now: now);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateTime _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }
}

import 'package:intl/intl.dart';

DateTime getNthDayOfWeek(DateTime date, int targetWeekday) {
  int difference = targetWeekday - date.weekday;
  return date.add(Duration(days: difference));
}

String formatDate(String format, DateTime date) {
  return DateFormat(format).format(date);
}


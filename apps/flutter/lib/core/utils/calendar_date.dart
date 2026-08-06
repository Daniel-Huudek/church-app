/// Helpers for API date-only fields stored as midnight (often UTC).
///
/// Do not call [DateTime.toLocal] before reading year/month/day for these
/// values — in Brazil that shifts UTC midnight to the previous civil day.
library;

/// Calendar day (year/month/day) in the timezone of [value].
DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Local calendar day for "today".
DateTime calendarToday([DateTime? now]) {
  final current = now ?? DateTime.now();
  return DateTime(current.year, current.month, current.day);
}

/// True when [date]'s calendar day is before today's calendar day.
bool isCalendarDateBeforeToday(DateTime date, [DateTime? now]) =>
    calendarDate(date).isBefore(calendarToday(now));

/// True when [date]'s calendar day is today or in the future.
bool isCalendarDateTodayOrFuture(DateTime date, [DateTime? now]) =>
    !isCalendarDateBeforeToday(date, now);

/// YYYY-MM-DD payload for date-only API fields.
String calendarDatePayload(DateTime date) {
  final day = calendarDate(date);
  final month = day.month.toString().padLeft(2, '0');
  final dayNum = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayNum';
}

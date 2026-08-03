import 'package:church_app_mobile/core/utils/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendarDate', () {
    test('keeps UTC midnight on the same civil day', () {
      final utcMidnight = DateTime.parse('2026-08-03T00:00:00.000Z');
      final day = calendarDate(utcMidnight);

      expect(day.year, 2026);
      expect(day.month, 8);
      expect(day.day, 3);
      expect(day.isUtc, isFalse);
    });
  });

  group('isCalendarDateBeforeToday / isCalendarDateTodayOrFuture', () {
    final now = DateTime(2026, 8, 3, 15, 30);

    test('treats UTC midnight of today as today, not past', () {
      final todayUtc = DateTime.parse('2026-08-03T00:00:00.000Z');

      expect(isCalendarDateBeforeToday(todayUtc, now), isFalse);
      expect(isCalendarDateTodayOrFuture(todayUtc, now), isTrue);
    });

    test('treats UTC midnight of yesterday as past', () {
      final yesterdayUtc = DateTime.parse('2026-08-02T00:00:00.000Z');

      expect(isCalendarDateBeforeToday(yesterdayUtc, now), isTrue);
      expect(isCalendarDateTodayOrFuture(yesterdayUtc, now), isFalse);
    });

    test('treats UTC midnight of tomorrow as future', () {
      final tomorrowUtc = DateTime.parse('2026-08-04T00:00:00.000Z');

      expect(isCalendarDateBeforeToday(tomorrowUtc, now), isFalse);
      expect(isCalendarDateTodayOrFuture(tomorrowUtc, now), isTrue);
    });

    test('instant comparison wrongly marks today as past in Brazil-like offset', () {
      // Documents the bug: UTC midnight is still "yesterday evening" locally
      // when the device is behind UTC (e.g. America/Sao_Paulo).
      final todayUtc = DateTime.parse('2026-08-03T00:00:00.000Z');
      final startOfTodayLocal = DateTime(now.year, now.month, now.day);
      final localInstant = todayUtc.toLocal();

      if (localInstant.isBefore(startOfTodayLocal)) {
        expect(isCalendarDateTodayOrFuture(todayUtc, now), isTrue);
      }
    });
  });

  group('calendarDatePayload', () {
    test('formats date-only as YYYY-MM-DD from UTC midnight', () {
      final utcMidnight = DateTime.parse('2026-08-03T00:00:00.000Z');
      expect(calendarDatePayload(utcMidnight), '2026-08-03');
    });
  });
}

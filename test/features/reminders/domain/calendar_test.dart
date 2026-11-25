import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';

void main() {
  test('leap years follow the Gregorian rules', () {
    expect(LocalDate.isLeapYear(2028), isTrue);
    expect(LocalDate.isLeapYear(2100), isFalse);
    expect(LocalDate.isLeapYear(2000), isTrue);
    expect(LocalDate.isLeapYear(2027), isFalse);
  });

  test('rejects dates that do not exist', () {
    expect(() => LocalDate(2027, 2, 29), throwsArgumentError);
    expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
    expect(() => LocalTime(24, 0), throwsArgumentError);
  });

  test('clamped uses the last day of a shorter month', () {
    expect(LocalDate.clamped(2026, 4, 31), LocalDate(2026, 4, 30));
    expect(LocalDate.clamped(2027, 2, 31), LocalDate(2027, 2, 28));
  });

  test('date arithmetic crosses month and year boundaries', () {
    expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
    expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
    expect(LocalDate(2026, 11, 25).monthsUntil(LocalDate(2027, 2, 1)), 3);
  });

  test('weekday is ISO numbered', () {
    expect(LocalDate(2026, 11, 23).weekday, DateTime.monday);
    expect(LocalDate(2026, 11, 29).weekday, DateTime.sunday);
  });
}

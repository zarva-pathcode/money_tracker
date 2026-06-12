import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/utils/period_helper.dart';

void main() {
  group('PeriodHelper.getPeriodStart', () {
    test('payDay 15, now tgl 20 — mulai dari tgl 15 bulan ini', () {
      final now = DateTime(2026, 6, 20);
      final start = PeriodHelper.getPeriodStart(15, now: now);
      expect(start, DateTime(2026, 6, 15));
    });

    test('payDay 15, now tgl 10 — mulai dari tgl 15 bulan lalu', () {
      final now = DateTime(2026, 6, 10);
      final start = PeriodHelper.getPeriodStart(15, now: now);
      expect(start, DateTime(2026, 5, 15));
    });

    test('payDay 1, now tgl 1 — mulai hari ini', () {
      final now = DateTime(2026, 6, 1);
      final start = PeriodHelper.getPeriodStart(1, now: now);
      expect(start, DateTime(2026, 6, 1));
    });

    test('payDay 31 di Feb — clamp ke 28, now sebelum payDay → mundur ke Jan', () {
      final now = DateTime(2026, 2, 15);
      final start = PeriodHelper.getPeriodStart(31, now: now);
      expect(start, DateTime(2026, 1, 31));
    });

    test('payDay 30 di Jan, now tgl 25 — mulai dari 30 Des', () {
      final now = DateTime(2026, 1, 25);
      final start = PeriodHelper.getPeriodStart(30, now: now);
      expect(start, DateTime(2025, 12, 30));
    });
  });

  group('PeriodHelper.getPeriodEnd', () {
    test('payDay 15 — end = 14 bulan depan', () {
      final now = DateTime(2026, 6, 20);
      final end = PeriodHelper.getPeriodEnd(15, now: now);
      expect(end, DateTime(2026, 7, 14));
    });

    test('payDay 1 — end = akhir bulan', () {
      final now = DateTime(2026, 6, 15);
      final end = PeriodHelper.getPeriodEnd(1, now: now);
      expect(end, DateTime(2026, 6, 30));
    });

    test('payDay 31 — end = 30 bulan depan (clamp)', () {
      final now = DateTime(2026, 1, 31);
      final end = PeriodHelper.getPeriodEnd(31, now: now);
      expect(end, DateTime(2026, 2, 27));
    });
  });

  group('PeriodHelper.isInPeriod', () {
    final now = DateTime(2026, 6, 20);

    test('tanggal dalam periode — return true', () {
      expect(
        PeriodHelper.isInPeriod(DateTime(2026, 6, 15), 15, now: now),
        true,
      );
    });

    test('tanggal sebelum periode — return false', () {
      expect(
        PeriodHelper.isInPeriod(DateTime(2026, 5, 14), 15, now: now),
        false,
      );
    });

    test('tanggal setelah periode — return false', () {
      expect(
        PeriodHelper.isInPeriod(DateTime(2026, 7, 15), 15, now: now),
        false,
      );
    });
  });
}

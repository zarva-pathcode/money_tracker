import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/expense.dart';
import 'package:money_tracker/services/subscription_service.dart';

void main() {
  group('SubscriptionService.detectSubscriptions', () {
    test('kurang dari 5 expenses — return []', () {
      final expenses = [
        Expense(id: '1', title: 'A', amount: 10000, date: DateTime(2026, 1, 5), category: 'Makanan'),
      ];
      expect(SubscriptionService.detectSubscriptions(expenses), isEmpty);
    });

    test('3 transaksi judul sama + tanggal mirip — detected', () {
      final expenses = [
        Expense(id: '1', title: 'Spotify', amount: 15000, date: DateTime(2026, 1, 5), category: 'Hiburan'),
        Expense(id: '2', title: 'Spotify', amount: 15000, date: DateTime(2026, 2, 5), category: 'Hiburan'),
        Expense(id: '3', title: 'Spotify', amount: 15000, date: DateTime(2026, 3, 7), category: 'Hiburan'),
        Expense(id: '4', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 1, 8), category: 'Makanan'),
        Expense(id: '5', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 2, 8), category: 'Makanan'),
      ];
      final result = SubscriptionService.detectSubscriptions(expenses);
      expect(result.length, 1);
      expect(result.first.title, 'Spotify');
      expect(result.first.dayOfMonth, 5);
    });

    test('transaksi dengan judul mirip — grouped by similarity', () {
      final expenses = [
        Expense(id: '1', title: 'Netflix', amount: 45000, date: DateTime(2026, 1, 10), category: 'Hiburan'),
        Expense(id: '2', title: 'netflix', amount: 45000, date: DateTime(2026, 2, 11), category: 'Hiburan'),
        Expense(id: '3', title: 'Netflix', amount: 45000, date: DateTime(2026, 3, 10), category: 'Hiburan'),
        Expense(id: '4', title: 'Beli Bensin', amount: 50000, date: DateTime(2026, 1, 15), category: 'Transportasi'),
        Expense(id: '5', title: 'Bensin', amount: 55000, date: DateTime(2026, 2, 15), category: 'Transportasi'),
      ];
      final result = SubscriptionService.detectSubscriptions(expenses);
      expect(result.length, 1);
    });

    test('transaksi < 3 kali — tidak terdeteksi', () {
      final expenses = [
        Expense(id: '1', title: 'Harian', amount: 5000, date: DateTime(2026, 1, 5), category: 'Makanan'),
        Expense(id: '2', title: 'Harian', amount: 5000, date: DateTime(2026, 2, 5), category: 'Makanan'),
      ];
      final result = SubscriptionService.detectSubscriptions(expenses);
      expect(result, isEmpty);
    });

    test('tanggal tidak konsisten (beda > 2 hari) — tidak terdeteksi', () {
      final expenses = [
        Expense(id: '1', title: 'AXIS', amount: 50000, date: DateTime(2026, 1, 5), category: 'Telepon'),
        Expense(id: '2', title: 'AXIS', amount: 50000, date: DateTime(2026, 2, 5), category: 'Telepon'),
        Expense(id: '3', title: 'AXIS', amount: 50000, date: DateTime(2026, 3, 15), category: 'Telepon'),
        Expense(id: '4', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 1, 8), category: 'Makanan'),
        Expense(id: '5', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 2, 8), category: 'Makanan'),
      ];
      final result = SubscriptionService.detectSubscriptions(expenses);
      expect(result, isEmpty);
    });

    test('kategori Tabungan di-skip', () {
      final expenses = [
        Expense(id: '1', title: 'Tabungan', amount: 100000, date: DateTime(2026, 1, 5), category: 'Tabungan'),
        Expense(id: '2', title: 'Tabungan', amount: 100000, date: DateTime(2026, 2, 5), category: 'Tabungan'),
        Expense(id: '3', title: 'Tabungan', amount: 100000, date: DateTime(2026, 3, 5), category: 'Tabungan'),
        Expense(id: '4', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 1, 8), category: 'Makanan'),
        Expense(id: '5', title: 'Makan Siang', amount: 25000, date: DateTime(2026, 2, 8), category: 'Makanan'),
      ];
      final result = SubscriptionService.detectSubscriptions(expenses);
      expect(result, isEmpty);
    });
  });

  group('SubscriptionInfo.fromMap / toMap', () {
    test('toMap lalu fromMap — data sama', () {
      final original = SubscriptionInfo(
        key: 'netflix',
        title: 'Netflix',
        category: 'Hiburan',
        amount: 45000,
        dayOfMonth: 10,
        isAutoDetected: true,
        isActive: true,
      );
      final map = original.toMap();
      final restored = SubscriptionInfo.fromMap(map);
      expect(restored.key, original.key);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.dayOfMonth, original.dayOfMonth);
      expect(restored.isAutoDetected, true);
    });

    test('fromMap dengan nilai default', () {
      final map = <String, dynamic>{
        'key': 'test',
        'title': 'Test',
        'category': 'Lainnya',
        'amount': 10000,
        'dayOfMonth': 1,
      };
      final sub = SubscriptionInfo.fromMap(map);
      expect(sub.isAutoDetected, false);
      expect(sub.isActive, true);
    });
  });

  group('SubscriptionService.isKnownSubscription', () {
    test('title cocok — return true', () {
      final subs = [
        SubscriptionInfo(key: 's', title: 'Spotify', category: 'Hiburan', amount: 15000, dayOfMonth: 5),
      ];
      expect(SubscriptionService.isKnownSubscription('Spotify', subs), true);
    });

    test('title sedikit berbeda — return true (fuzzy)', () {
      final subs = [
        SubscriptionInfo(key: 's', title: 'Langganan Spotify', category: 'Hiburan', amount: 15000, dayOfMonth: 5),
      ];
      expect(SubscriptionService.isKnownSubscription('Spotify', subs), true);
    });

    test('title beda total — return false', () {
      final subs = [
        SubscriptionInfo(key: 'g', title: 'Grab', category: 'Transportasi', amount: 10000, dayOfMonth: 15),
      ];
      expect(SubscriptionService.isKnownSubscription('Netflix', subs), false);
    });

    test('list kosong — return false', () {
      expect(SubscriptionService.isKnownSubscription('Any', []), false);
    });
  });
}

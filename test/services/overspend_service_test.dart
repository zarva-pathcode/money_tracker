import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/plan_item.dart';
import 'package:money_tracker/services/overspend_service.dart';

void main() {
  group('OverspendService.calculateProportionalAllocation', () {
    PlanItem _plan(String id, String title, double current, double target) {
      return PlanItem(
        id: id,
        title: title,
        currentAmount: current,
        targetAmount: target,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe800,
      );
    }

    test('distribusi proporsional ke semua plan', () {
      final plans = [
        _plan('1', 'A', 40000, 100000),
        _plan('2', 'B', 60000, 100000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 50000,
        totalPlansBalance: 100000,
      );
      expect(result['1'], closeTo(20000, 1));
      expect(result['2'], closeTo(30000, 1));
    });

    test('shortfall lebih besar dari balance total — ambil semua', () {
      final plans = [
        _plan('1', 'A', 30000, 50000),
        _plan('2', 'B', 10000, 50000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 100000,
        totalPlansBalance: 40000,
      );
      expect(result['1'], closeTo(30000, 1));
      expect(result['2'], closeTo(10000, 1));
      final total = result.values.fold<double>(0, (s, v) => s + v);
      expect(total, closeTo(40000, 1));
    });

    test('shortfall 0 — semua alokasi 0', () {
      final plans = [
        _plan('1', 'A', 50000, 100000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 0,
        totalPlansBalance: 50000,
      );
      expect(result['1'], 0);
    });

    test('satu plan dengan balance cukup', () {
      final plans = [
        _plan('1', 'A', 100000, 100000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 25000,
        totalPlansBalance: 100000,
      );
      expect(result['1'], 25000);
    });

    test('totalPlansBalance 0 — semua alokasi 0', () {
      final plans = [
        _plan('1', 'A', 0, 50000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 10000,
        totalPlansBalance: 0,
      );
      expect(result['1'], 0);
    });

    test('rebalance ketika satu plan di-0-kan', () {
      final plans = [
        _plan('1', 'A', 10000, 50000),
        _plan('2', 'B', 10000, 50000),
      ];
      final result = OverspendService.calculateProportionalAllocation(
        plans: plans,
        shortfall: 15000,
        totalPlansBalance: 20000,
      );
      final total = result.values.fold<double>(0, (s, v) => s + v);
      expect(total, closeTo(15000, 100));
    });
  });
}

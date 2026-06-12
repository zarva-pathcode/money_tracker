import '../../models/plan_item.dart';
import '../../providers/expense_provider.dart';
import '../../providers/plan_provider.dart';

class OverspendService {
  static Map<String, double> calculateProportionalAllocation({
    required List<PlanItem> plans,
    required double shortfall,
    required double totalPlansBalance,
  }) {
    final allocations = <String, double>{};
    for (final plan in plans) {
      final autoAmount = totalPlansBalance > 0
          ? ((plan.currentAmount / totalPlansBalance) * shortfall)
              .clamp(0.0, plan.currentAmount)
          : 0.0;
      allocations[plan.id] = autoAmount;
    }
    return _rebalanceAllocations(allocations, plans, shortfall);
  }

  static Map<String, double> _rebalanceAllocations(
    Map<String, double> allocations,
    List<PlanItem> plans,
    double shortfall,
  ) {
    final selectedIds =
        allocations.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    if (selectedIds.isEmpty) return allocations;

    final totalSelected =
        selectedIds.fold<double>(0, (sum, id) => sum + allocations[id]!);
    if (totalSelected == 0) return allocations;

    for (final id in selectedIds) {
      final plan = plans.firstWhere((p) => p.id == id);
      final ratio = allocations[id]! / totalSelected;
      allocations[id] = (ratio * shortfall).clamp(0.0, plan.currentAmount);
    }

    final totalNow =
        selectedIds.fold<double>(0, (sum, id) => sum + allocations[id]!);
    if ((totalNow - shortfall).abs() > 1 && selectedIds.isNotEmpty) {
      final largestId = selectedIds
          .reduce((a, b) => allocations[a]! > allocations[b]! ? a : b);
      final largestPlan = plans.firstWhere((p) => p.id == largestId);
      allocations[largestId] =
          (allocations[largestId]! + (shortfall - totalNow))
              .clamp(0.0, largestPlan.currentAmount);
    }

    return allocations;
  }

  static Future<void> executeAllocations({
    required Map<String, double> allocations,
    required List<PlanItem> plans,
    required ExpenseProvider expenseProvider,
    required PlanProvider planProvider,
  }) async {
    for (final entry in allocations.entries) {
      if (entry.value <= 0) continue;
      final plan = plans.firstWhere((p) => p.id == entry.key);
      await expenseProvider.withdrawSavingsAllocation(
        amount: entry.value,
        planTitle: plan.title,
      );
      await planProvider.withdrawFromPlan(entry.key, entry.value);
    }
  }
}

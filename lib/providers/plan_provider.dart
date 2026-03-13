import 'package:flutter/material.dart';
import '../models/plan_item.dart';
import '../services/hive_service.dart';

class PlanProvider with ChangeNotifier {
  List<PlanItem> _plans = [];

  List<PlanItem> get plans => _plans;

  PlanProvider() {
    _loadPlans();
  }

  void _loadPlans() {
    _plans = HiveService.getAllPlans();
    notifyListeners();
  }

  Future<void> addPlan(PlanItem plan) async {
    await HiveService.addPlan(plan);
    _loadPlans();
  }

  Future<void> updatePlan(PlanItem plan) async {
    await HiveService.updatePlan(plan);
    _loadPlans();
  }

  Future<void> deletePlan(String id) async {
    await HiveService.deletePlan(id);
    _loadPlans();
  }

  Future<void> addFundToPlan(String id, double amount) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plan = _plans[index];
      final newCurrentAmount = plan.currentAmount + amount;

      final updatedPlan = PlanItem(
        id: plan.id,
        title: plan.title,
        targetAmount: plan.targetAmount,
        currentAmount: newCurrentAmount,
        colorValue: plan.colorValue,
        iconCodePoint: plan.iconCodePoint,
      );

      await updatePlan(updatedPlan);
    }
  }
}

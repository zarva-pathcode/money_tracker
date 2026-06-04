import 'package:flutter/material.dart';
import '../models/plan_item.dart';
import '../services/hive_service.dart';

class PlanProvider with ChangeNotifier {
  final HiveService _hiveService;
  List<PlanItem> _plans = [];

  List<PlanItem> get plans => _plans;

  PlanProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadPlans();
  }

  void _loadPlans() {
    _plans = _hiveService.getAllPlans();
    notifyListeners();
  }

  Future<void> addPlan(PlanItem plan) async {
    await _hiveService.addPlan(plan);
    _loadPlans();
  }

  Future<void> updatePlan(PlanItem plan) async {
    await _hiveService.updatePlan(plan);
    _loadPlans();
  }

  Future<void> deletePlan(String id) async {
    await _hiveService.deletePlan(id);
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

  Future<void> withdrawFromPlan(String id, double amount) async {
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final plan = _plans[index];
      final newCurrentAmount = (plan.currentAmount - amount).clamp(0.0, plan.currentAmount);

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

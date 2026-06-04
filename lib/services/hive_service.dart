import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/expense.dart';
import '../models/plan_item.dart';
import '../models/budget_item.dart';

class HiveService {
  static const String expenseBoxName = 'expenses';
  static const String settingsBoxName = 'settings';
  static const String planBoxName = 'plans';
  static const String budgetBoxName = 'budgets';

  Future<void> init() async {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(PlanItemAdapter());
    Hive.registerAdapter(BudgetItemAdapter());

    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<PlanItem>(planBoxName);
    await Hive.openBox<BudgetItem>(budgetBoxName);
  }

  Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(expenseBoxName);
  }

  Box<PlanItem> getPlanBox() {
    return Hive.box<PlanItem>(planBoxName);
  }

  Box<BudgetItem> getBudgetBox() {
    return Hive.box<BudgetItem>(budgetBoxName);
  }

  // --- SETTINGS ---

  T getSetting<T>(String key, T defaultValue) {
    final box = Hive.box(settingsBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> setSetting<T>(String key, T value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(key, value);
  }

  // --- ONBOARDING ---

  bool isFirstTime() {
    return getSetting('hasSeenOnboarding', true);
  }

  Future<void> setOnboardingSeen() async {
    await setSetting('hasSeenOnboarding', false);
  }

  // --- EXPENSE CRUD ---

  Future<void> addExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  Future<void> updateExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  List<Expense> getAllExpenses() {
    final box = getExpenseBox();
    return box.values.toList();
  }

  Future<void> deleteExpense(String id) async {
    final box = getExpenseBox();
    await box.delete(id);
  }

  Future<void> clearAllExpenses() async {
    final box = getExpenseBox();
    await box.clear();
  }

  // --- PLAN CRUD ---
  
  Future<void> addPlan(PlanItem plan) async {
    final box = getPlanBox();
    await box.put(plan.id, plan);
  }

  Future<void> updatePlan(PlanItem plan) async {
    final box = getPlanBox();
    await box.put(plan.id, plan);
  }

  List<PlanItem> getAllPlans() {
    final box = getPlanBox();
    return box.values.toList();
  }

  Future<void> deletePlan(String id) async {
    final box = getPlanBox();
    await box.delete(id);
  }

  // --- BUDGET CRUD ---

  Future<void> addBudget(BudgetItem item) async {
    final box = getBudgetBox();
    await box.put(item.id, item);
  }

  Future<void> updateBudget(BudgetItem item) async {
    final box = getBudgetBox();
    await box.put(item.id, item);
  }

  List<BudgetItem> getAllBudgets() {
    final box = getBudgetBox();
    return box.values.toList();
  }

  Future<void> deleteBudget(String id) async {
    final box = getBudgetBox();
    await box.delete(id);
  }
}


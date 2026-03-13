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

  static Future<void> init() async {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(PlanItemAdapter());
    Hive.registerAdapter(BudgetItemAdapter());

    // Buka box
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<PlanItem>(planBoxName);
    await Hive.openBox<BudgetItem>(budgetBoxName);
  }

  static Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(expenseBoxName);
  }

  static Box<PlanItem> getPlanBox() {
    return Hive.box<PlanItem>(planBoxName);
  }

  static Box<BudgetItem> getBudgetBox() {
    return Hive.box<BudgetItem>(budgetBoxName);
  }

  // --- LOGIC ONBOARDING ---

  // Cek apakah user baru (Default true jika belum ada data)
  static bool isFirstTime() {
    final box = Hive.box(settingsBoxName);
    return box.get('hasSeenOnboarding', defaultValue: true);
  }

  // Set status bahwa user sudah melihat onboarding
  static Future<void> setOnboardingSeen() async {
    final box = Hive.box(settingsBoxName);
    await box.put('hasSeenOnboarding', false);
  }

  // --- EXPENSE CRUD (Tetap Sama) ---

  static Future<void> addExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  static Future<void> updateExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  static List<Expense> getAllExpenses() {
    final box = getExpenseBox();
    return box.values.toList();
  }

  static Future<void> deleteExpense(String id) async {
    final box = getExpenseBox();
    await box.delete(id);
  }

  static Future<void> clearAllExpenses() async {
    final box = getExpenseBox();
    await box.clear();
  }

  // --- PLAN CRUD ---
  
  static Future<void> addPlan(PlanItem plan) async {
    final box = getPlanBox();
    await box.put(plan.id, plan);
  }

  static Future<void> updatePlan(PlanItem plan) async {
    final box = getPlanBox();
    await box.put(plan.id, plan);
  }

  static List<PlanItem> getAllPlans() {
    final box = getPlanBox();
    return box.values.toList();
  }

  static Future<void> deletePlan(String id) async {
    final box = getPlanBox();
    await box.delete(id);
  }

  // --- BUDGET CRUD ---

  static Future<void> addBudget(BudgetItem item) async {
    final box = getBudgetBox();
    await box.put(item.id, item);
  }

  static Future<void> updateBudget(BudgetItem item) async {
    final box = getBudgetBox();
    await box.put(item.id, item);
  }

  static List<BudgetItem> getAllBudgets() {
    final box = getBudgetBox();
    return box.values.toList();
  }

  static Future<void> deleteBudget(String id) async {
    final box = getBudgetBox();
    await box.delete(id);
  }
}


import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/expense.dart';

class HiveService {
  static const String expenseBoxName = 'expenses';
  static const String settingsBoxName = 'settings'; // Box baru untuk pengaturan

  static Future<void> init() async {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    Hive.registerAdapter(ExpenseAdapter());

    // Buka kedua box
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(expenseBoxName);
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
}

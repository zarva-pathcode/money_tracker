---
name: coding-standards
description: Baseline cross-project coding conventions for naming, readability, immutability, and code-quality review. Use dart-flutter-patterns for framework-specific patterns.
origin: ECC
---

# Coding Standards & Best Practices

Baseline coding conventions applicable across projects.

Gunakan `dart-flutter-patterns` atau `flutter-dart-code-review` untuk pattern spesifik Flutter/Dart.

## When to Activate

- Starting a new project or module
- Reviewing code for quality and maintainability
- Refactoring existing code to follow conventions
- Enforcing naming, formatting, or structural consistency

## Code Quality Principles

### 1. Readability First
- Code is read more than written
- Clear variable and function names
- Self-documenting code preferred over comments
- Consistent formatting

### 2. KISS (Keep It Simple, Stupid)
- Simplest solution that works
- Avoid over-engineering
- No premature optimization
- Easy to understand > clever code

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into functions
- Create reusable components
- Share utilities across modules
- Avoid copy-paste programming

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

## Dart Naming Conventions

### Variable & Field Naming

```dart
// PASS: Descriptive names
final String searchQuery = '';
final bool isAuthenticated = false;
final double totalRevenue = 1000;

// FAIL: Unclear names
final q = '';
final flag = false;
final x = 1000;
```

### Function Naming

```dart
// PASS: Verb-noun pattern
Future<List<Expense>> fetchExpenses() async { }
double calculateTotal(List<Expense> items) { }
bool isValidEmail(String email) => ...

// FAIL: Unclear or noun-only
Future<List<Expense>> expenses() async { }
double calc(List<Expense> items) { }
bool email(String e) => ...
```

### Immutability Pattern (CRITICAL)

```dart
// PASS: Gunakan final + copyWith pattern
final updatedUser = user.copyWith(name: 'New Name');
final updatedList = [...items, newItem];

// FAIL: Mutasi langsung
user.name = 'New Name';  // BAD — unless using provider state
items.add(newItem);       // BAD — unless local list
```

### Error Handling

```dart
// PASS: Comprehensive error handling
Future<Expense> fetchExpense(String id) async {
  try {
    final expense = await hiveService.getExpense(id);
    if (expense == null) {
      throw Exception('Expense not found: $id');
    }
    return expense;
  } on HiveError catch (e) {
    log('Hive error: $e');
    rethrow;
  } catch (e) {
    log('Unexpected error: $e');
    rethrow;
  }
}

// FAIL: No error handling or catch too broad
Future<Expense> fetchExpense(String id) async {
  return await hiveService.getExpense(id);
}
```

### Async/Await Best Practices

```dart
// PASS: Parallel execution when possible
final (expenses, plans, budgets) = await (
  expenseProvider.loadExpenses(),
  planProvider.loadPlans(),
  budgetProvider.loadBudgets(),
).wait;

// PASS: mounted check after await in StatefulWidget
if (!mounted) return;

// FAIL: Sequential when unnecessary
final expenses = await expenseProvider.loadExpenses();
final plans = await planProvider.loadPlans(); // BAD — bisa parallel
```

## Flutter File Organization

```
lib/
├── main.dart                  # Entry point + provider setup
├── models/                    # Data models (Hive)
├── providers/                 # State layer (ChangeNotifier)
├── services/                  # Logic layer (HiveService, parsers)
├── screens/                   # UI pages
├── widgets/                   # Reusable widget components
├── utils/                     # Helpers, constants, formatters
└── themes/                    # ThemeData configuration
```

### File Naming

```
snake_case for files:
  expense_provider.dart
  add_expense_screen.dart
  category_picker.dart

PascalCase for classes:
  class ExpenseProvider extends ChangeNotifier
  class AddExpenseScreen extends StatefulWidget
  class CategoryPicker extends StatelessWidget
```

## Comments & Documentation

### When to Comment — Explain WHY, not WHAT

```dart
// PASS: Explain WHY
// Gunakan exponential backoff agar tidak membanjiri Hive
final delay = Duration(milliseconds: 100 * pow(2, retryCount).toInt());

// FAIL: Stating the obvious
// Increment counter
count++;
```

### Doc Comments for Public APIs

```dart
/// Menghitung shortfall untuk overspend check.
///
/// [amount] adalah nilai transaksi baru.
/// [payDay] menentukan periode yang digunakan.
/// Returns shortfall, atau 0 jika tidak overspend.
double checkShortfall(double amount, {required int payDay}) {
  // Implementation
}
```

## Code Smell Detection

### 1. Long Functions / Widget Build Methods

```dart
// FAIL: BAD — build method > 100 lines
@override
Widget build(BuildContext context) {
  // 150 lines of nested widgets
}

// PASS: GOOD — ekstrak ke widget terpisah
@override
Widget build(BuildContext context) {
  return Column(children: [
    const HeroCard(),
    const TransactionList(),
    const BottomNav(),
  ]);
}
```

### 2. Deep Nesting

```dart
// FAIL: BAD — 5+ levels of nesting
if (expense != null) {
  if (expense.type == 'expense') {
    if (expense.amount > 0) {
      if (isInPeriod(expense.date, payDay)) {
        // Do something
      }
    }
  }
}

// PASS: GOOD — Early returns / guard clauses
if (expense == null) return;
if (expense.type != 'expense') return;
if (expense.amount <= 0) return;
if (!isInPeriod(expense.date, payDay)) return;

// Do something
```

### 3. Magic Numbers

```dart
// FAIL: BAD — unexplained numbers
if (retryCount > 3) { }
padding: const EdgeInsets.all(16),

// PASS: GOOD — named constants
static const int maxRetries = 3;
static const double cardPadding = 16.0;

if (retryCount > maxRetries) { }
padding: const EdgeInsets.all(cardPadding),
```

### 4. Tidak Menggunakan `const` di Widget Tree

```dart
// FAIL: BAD — new instance setiap rebuild
child: Padding(
  padding: EdgeInsets.all(16.0),     // tidak const
  child: Icon(Icons.home, size: 24), // tidak const
)

// PASS: GOOD — const mencegah rebuild tidak perlu
child: const Padding(
  padding: EdgeInsets.all(16.0),
  child: Icon(Icons.home, size: 24),
)
```

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.

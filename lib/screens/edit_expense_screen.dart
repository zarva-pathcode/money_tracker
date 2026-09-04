import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:money_tracker/utils/formatters.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/numeric_input_controller.dart';
import '../widgets/numeric_keyboard.dart';
import '../widgets/modern_input_field.dart';
import '../widgets/transaction_mode_segment.dart';
import '../widgets/amount_hero_input.dart';
import '../widgets/category_picker.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  final Function(Expense) onSave;

  const EditExpenseScreen({
    super.key,
    required this.expense,
    required this.onSave,
  });

  @override
  _EditExpenseScreenState createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late final NumericInputController _numericInput;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _transactionType;

  bool _showCustomKeyboard = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
      text: Formatters.formatNumberInput(
        widget.expense.amount.toStringAsFixed(0),
      ),
    );
    _numericInput = NumericInputController(controller: _amountController);
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
    _transactionType = widget.expense.type;

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) setState(() => _showCustomKeyboard = false);
    });

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = true);
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _amountController.addListener(_numericInput.updateCursorPosition);
  }

  void _handleKeyPress(String key) {
    _numericInput.handleKeyPress(key);
  }

  void _handleBackspace() {
    _numericInput.handleBackspace();
  }

  /// Menambahkan nominal cepat ke nilai saat ini (pill +10rb dst).
  void _addQuickAmount(int value) {
    final current = Formatters.parseFormattedNumber(_amountController.text);
    _amountController.text = Formatters.formatNumberInput(
      (current + value).toInt().toString(),
    );
  }

  void _handleKeyboardSubmit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount > 0) {
      setState(() => _showCustomKeyboard = false);
      FocusScope.of(context).requestFocus(_titleFocusNode);
    }
  }

  void _onTitleSubmitted(String value) {
    _saveExpense();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _transactionType == 'expense' ? 'Edit Pengeluaran' : 'Edit Pemasukan',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    TransactionModeSegment(
                      currentType: _transactionType,
                      onTypeChanged: (type) {
                        setState(() {
                          _transactionType = type;
                          if (_transactionType == 'income') {
                            if (!Constants.incomeCategories.contains(_selectedCategory)) {
                              _selectedCategory = Constants.incomeCategories.first;
                            }
                          } else {
                            if (!Constants.expenseCategories.contains(_selectedCategory)) {
                              _selectedCategory = Constants.expenseCategories.first;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Kartu hero nominal + pill cepat
                    AmountHeroInput(
                      controller: _amountController,
                      transactionType: _transactionType,
                      onTapAmount: () {
                        setState(() => _showCustomKeyboard = true);
                        FocusScope.of(context).requestFocus(_amountFocusNode);
                      },
                      onClear: () => _amountController.clear(),
                      onQuickAdd: _addQuickAmount,
                    ),

                    const SizedBox(height: 16),

                    // Row for Date and Note
                    Row(
                      children: [
                        // Date Picker (Modern Compact)
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Note Input Modern
                        Expanded(
                          child: ModernInputField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            hintText: "Catatan...",
                            icon: Icons.edit_note_rounded,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _onTitleSubmitted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    CategoryPicker(
                      selectedCategory: _selectedCategory,
                      transactionType: _transactionType,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Action Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              _showCustomKeyboard
                  ? 12
                  : (12 + MediaQuery.of(context).padding.bottom),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _saveExpense(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                "Update Transaksi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Custom Keyboard
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height:
                _showCustomKeyboard
                    ? (280 + MediaQuery.of(context).padding.bottom)
                    : 0,
            child:
                _showCustomKeyboard
                    ? Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Divider(height: 1, thickness: 0.5),
                          Expanded(
                            child: NumericKeyboard(
                              onKeyPressed: _handleKeyPress,
                              onBackspace: _handleBackspace,
                              onSubmit: _handleKeyboardSubmit,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );
      });
    }
  }

  Future<void> _saveExpense() async {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah harus lebih dari 0")),
      );
      return;
    }

    // Check overspend only if editing an expense with higher amount
    if (_transactionType == 'expense' && amount > widget.expense.amount) {
      final delta = amount - widget.expense.amount;
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final proceed = await expenseProvider.handleOverspendIfNeeded(
        amount: delta,
        payDay: settingsProvider.periodStartDay,
        context: context,
        planProvider: planProvider,
      );
      if (!proceed) return;
    }

    final updatedExpense = Expense(
      id: widget.expense.id,
      title: _titleController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: _transactionType,
    );
    widget.onSave(updatedExpense);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _titleFocusNode.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _numericInput.dispose();
    super.dispose();
  }
}

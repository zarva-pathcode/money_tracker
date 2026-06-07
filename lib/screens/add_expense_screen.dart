import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/plan_item.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/numeric_input_controller.dart';
import '../services/overspend_service.dart';
import '../widgets/numeric_keyboard.dart';
import '../widgets/modern_input_field.dart';
import '../widgets/overspend_bottom_sheet.dart';
import '../widgets/transaction_type_toggle.dart';
import '../widgets/category_picker.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? preSelectedCategory;
  final String? initialTransactionType; // 'expense' or 'income'
  final double? preFilledAmount;

  const AddExpenseScreen({
    super.key,
    this.preSelectedCategory,
    this.initialTransactionType,
    this.preFilledAmount,
  });

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late final NumericInputController _numericInput;

  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'expense'; // 'expense' or 'income'

  bool _payFromSavings = false;
  PlanItem? _selectedGoal;
  List<PlanItem> _plans = [];

  // Focus Nodes untuk mengatur perpindahan kursor
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  bool _showCustomKeyboard =
      true; // Default true agar langsung muncul saat dibuka

  @override
  void initState() {
    super.initState();
    _numericInput = NumericInputController(controller: _amountController);

    if (widget.initialTransactionType != null) {
      _transactionType = widget.initialTransactionType!;
      if (_transactionType == 'income') {
        _selectedCategory = Constants.incomeCategories.first;
      }
    }

    if (widget.preSelectedCategory != null) {
      _selectedCategory = widget.preSelectedCategory!;
    }

    if (widget.preFilledAmount != null && widget.preFilledAmount! > 0) {
      _amountController.text = Formatters.formatNumberInput(
        widget.preFilledAmount!.toInt().toString(),
      );
    }

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = false);
      }
    });

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = true);
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _amountController.addListener(_numericInput.updateCursorPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      final plans = Provider.of<PlanProvider>(context, listen: false).plans;
      _plans = plans.where((p) => p.currentAmount > 0).toList();
    });
  }

  void _handleKeyPress(String key) {
    _numericInput.handleKeyPress(key);
  }

  void _handleBackspace() {
    _numericInput.handleBackspace();
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
          _transactionType == 'expense'
              ? 'Tambah Pengeluaran'
              : 'Tambah Pemasukan',
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 6,
              ),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TransactionTypeToggle(
                      currentType: _transactionType,
                      onTypeChanged: (type) {
                        setState(() {
                          _transactionType = type;
                          _payFromSavings = false;
                          _selectedGoal = null;
                          if (type == 'income') {
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

                    // Input Nominal Modern
                    ModernInputField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      hintText: "0",
                      icon: Icons.account_balance_wallet_rounded,
                      readOnly: true,
                      prefixText: "Rp ",
                      onTap: () {
                        setState(() => _showCustomKeyboard = true);
                        FocusScope.of(context).requestFocus(_amountFocusNode);
                      },
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                              ),
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
                                  DateFormat('dd MMM').format(_selectedDate),
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

                    const SizedBox(height: 20),
                    CategoryPicker(
                      selectedCategory: _selectedCategory,
                      transactionType: _transactionType,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 16),
                    if (_transactionType == 'expense' && _plans.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Bayar dari Tabungan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'Kurangi saldo ${_selectedGoal != null ? _selectedGoal!.title : 'goal'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: _payFromSavings,
                              onChanged: (val) => setState(() {
                                _payFromSavings = val;
                                if (val && _plans.isNotEmpty && _selectedGoal == null) {
                                  _selectedGoal = _plans.first;
                                }
                              }),
                              activeColor: Theme.of(context).primaryColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              dense: true,
                            ),
                            if (_payFromSavings) ...[
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: DropdownButtonFormField<PlanItem>(
                                  value: _selectedGoal,
                                  decoration: const InputDecoration(
                                    labelText: 'Pilih Tabungan',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: _plans.map((plan) {
                                    return DropdownMenuItem(
                                      value: plan,
                                      child: Text(
                                        '${plan.title} — ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(plan.currentAmount)}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (plan) => setState(() {
                                    _selectedGoal = plan;
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
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
            child: ElevatedButton(
              onPressed: () => _saveExpense(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Simpan Transaksi",
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

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Mode: Bayar dari Tabungan — withdraw + skip overspend
    if (_payFromSavings && _transactionType == 'expense' && _selectedGoal != null) {
      await expenseProvider.withdrawSavingsAllocation(
        amount: amount,
        planTitle: _selectedGoal!.title,
      );
      await planProvider.withdrawFromPlan(_selectedGoal!.id, amount);
    } else if (_transactionType == 'expense') {
      // Check overspend only for expense transactions (bukan bayar dari tabungan)
      final shortfall = expenseProvider.checkShortfall(amount, payDay: settingsProvider.periodStartDay);
      if (shortfall > 0) {
        final plans =
            planProvider.plans.where((p) => p.currentAmount > 0).toList();
        if (plans.isNotEmpty) {
          final totalPlansBalance =
              plans.fold<double>(0, (sum, p) => sum + p.currentAmount);

          final allocations =
              await showModalBottomSheet<Map<String, double>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => OverspendBottomSheet(
              shortfall: shortfall,
              plans: plans,
              totalPlansBalance: totalPlansBalance,
            ),
          );

          if (allocations == null) return;

          await OverspendService.executeAllocations(
            allocations: allocations,
            plans: planProvider.plans,
            expenseProvider: expenseProvider,
            planProvider: planProvider,
          );
        }
      }
    }

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: _transactionType,
    );

    await expenseProvider.addExpense(newExpense);
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

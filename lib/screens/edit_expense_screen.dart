import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/utils/formartters.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../widgets/numeric_keyboard.dart';
import '../widgets/modern_input_field.dart';

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

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _transactionType;

  bool _showCustomKeyboard = false;
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
      text: Formatters.formatNumberInput(
        widget.expense.amount.toStringAsFixed(0),
      ),
    );
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

    _amountController.addListener(_updateCursorPosition);
  }

  void _updateCursorPosition() {
    _cursorPosition = _amountController.selection.baseOffset;
  }

  void _handleKeyPress(String key) {
    final currentText = _amountController.text.replaceAll('.', '');
    final currentCursor = _cursorPosition < 0 ? 0 : _cursorPosition;
    String newText = "";
    int nextCursor = 0;

    if (key == '.000') {
      if (currentText.length + 3 > 15) return;
      newText =
          currentText.substring(0, currentCursor) +
          '000' +
          currentText.substring(currentCursor);
      nextCursor = currentCursor + 3;
    } else {
      if (currentText.length + 1 > 15) return;
      newText =
          currentText.substring(0, currentCursor) +
          key +
          currentText.substring(currentCursor);
      nextCursor = currentCursor + 1;
    }
    _updateTextField(newText, nextCursor);
  }

  void _handleBackspace() {
    final currentText = _amountController.text.replaceAll('.', '');
    final currentCursor = _cursorPosition;
    if (currentCursor > 0) {
      final newText =
          currentText.substring(0, currentCursor - 1) +
          currentText.substring(currentCursor);
      _updateTextField(newText, currentCursor - 1);
    }
  }

  void _updateTextField(String newText, int newCursorPosition) {
    final formattedText = Formatters.formatNumberInput(newText);
    final adjustedCursor = _calculateAdjustedCursor(
      newText,
      formattedText,
      newCursorPosition,
    );
    _amountController.text = formattedText;
    _amountController.selection = TextSelection.collapsed(
      offset: adjustedCursor,
    );
  }

  int _calculateAdjustedCursor(
    String originalText,
    String formattedText,
    int originalCursor,
  ) {
    final textBeforeCursor = originalText.substring(0, originalCursor);
    final formattedBeforeCursor = Formatters.formatNumberInput(
      textBeforeCursor,
    );
    return formattedBeforeCursor.length;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildTypeToggle(),
                    const SizedBox(height: 32),

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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM').format(_selectedDate),
                                  style: TextStyle(
                                    color: Colors.blue[700],
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

                    // Category Selection Header
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Kategori",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Grid
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.start,
                      children:
                          (_transactionType == 'expense'
                                  ? Constants.expenseCategories
                                  : Constants.incomeCategories)
                              .map((category) => _buildCategoryItem(category))
                              .toList(),
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
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
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

  Widget _buildTypeToggle() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleItem("Pengeluaran", 'expense'),
          _buildToggleItem("Pemasukan", 'income'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, String type) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color:
                  isSelected
                      ? (type == 'expense'
                          ? Colors.red[700]
                          : Colors.green[700])
                      : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    final isSelected = _selectedCategory == category;
    final style = Constants.getCategoryStyle(category);
    final color = style['color'] as Color;
    final icon = style['icon'];

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[50],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
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
              primary: Colors.blue[800]!,
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

  void _saveExpense() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah harus lebih dari 0")),
      );
      return;
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
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _titleFocusNode.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

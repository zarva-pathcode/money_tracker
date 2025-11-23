import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/utils/formartters.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../widgets/numeric_keyboard.dart';

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

  // --- LOGIC NAVIGATION ---
  void _handleKeyboardSubmit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount > 0) {
      setState(() => _showCustomKeyboard = false);
      FocusScope.of(context).requestFocus(_titleFocusNode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi nominal pengeluaran dulu")),
      );
    }
  }

  void _onTitleSubmitted(String value) {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount <= 0) {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_amountFocusNode);
        setState(() => _showCustomKeyboard = true);
      });
    } else {
      _saveExpense();
    }
  }

  // --- HELPER KEYBOARD ---
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

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Pengeluaran',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Jumlah Pengeluaran",
                      style: TextStyle(color: Colors.grey),
                    ),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        showCursor: true,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          prefixText: "Rp ",
                          prefixStyle: TextStyle(
                            fontSize: 40,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          hintText: "0",
                          hintStyle: TextStyle(color: Colors.black12),
                        ),
                        onTap: () {
                          setState(() => _showCustomKeyboard = true);
                          FocusScope.of(context).requestFocus(_amountFocusNode);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Colors.blue[800],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM').format(_selectedDate),
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: _onTitleSubmitted,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Catatan...",
                                icon: Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Ubah Kategori",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children:
                          Constants.categories
                              .where((c) => c != 'Semua Kategori')
                              .map((category) => _buildCategoryItem(category))
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            // PERBAIKAN DISINI: Padding Bawah Dinamis
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              // Logika safe area
              _showCustomKeyboard
                  ? 12
                  : (12 + MediaQuery.of(context).padding.bottom),
            ),
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Update Pengeluaran",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // PERBAIKAN 1: Tambah tinggi safe area
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
                          const Divider(height: 1, thickness: 1),

                          Expanded(
                            child: NumericKeyboard(
                              onKeyPressed: _handleKeyPress,
                              onBackspace: _handleBackspace,
                              onSubmit: _handleKeyboardSubmit,
                            ),
                          ),

                          // PERBAIKAN 2: Spacer aman
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

  Widget _buildCategoryItem(String category) {
    final isSelected = _selectedCategory == category;
    final style = Constants.getCategoryStyle(category);
    final color = style['color'] as Color;
    final icon = style['icon'] as IconData;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[500],
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(
        () =>
            _selectedDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              _selectedDate.hour,
              _selectedDate.minute,
              _selectedDate.second,
            ),
      );
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

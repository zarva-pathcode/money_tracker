import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_item.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';
import '../utils/formartters.dart';
import 'numeric_keyboard.dart';

class AddBudgetBottomSheet extends StatefulWidget {
  final BudgetItem? budgetToEdit;

  const AddBudgetBottomSheet({super.key, this.budgetToEdit});

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  String? _selectedCategory;
  int _cursorPosition = 0;
  bool _showCustomKeyboard = false;

  final List<String> _expenseCategories = Constants.expenseCategories;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _selectedCategory = widget.budgetToEdit!.category;
      _amountController.text = Formatters.formatNumberInput(widget.budgetToEdit!.limitAmount.toInt().toString());
    } else {
      _amountController.text = '';
    }
    
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        setState(() {
          _showCustomKeyboard = true;
          _cursorPosition = _amountController.selection.baseOffset;
          if (_cursorPosition < 0) _cursorPosition = _amountController.text.length;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
      return;
    }

    final String formattedText = _amountController.text;
    final String currentText = formattedText.replaceAll('.', '');
    
    int unformattedCursor = 0;
    if (_cursorPosition >= 0 && _cursorPosition <= formattedText.length) {
      unformattedCursor = formattedText.substring(0, _cursorPosition).replaceAll('.', '').length;
    } else {
      unformattedCursor = currentText.length;
    }

    if (value == '.000') {
      if (currentText.isEmpty) {
        _updateTextField('000', 3);
      } else {
        if (currentText.length + 3 > 15) return;
        final newText = currentText.substring(0, unformattedCursor) +
            '000' +
            currentText.substring(unformattedCursor);
        _updateTextField(newText, unformattedCursor + 3);
      }
    } else {
      if (currentText.length + 1 > 15) return;
      final newText = currentText.substring(0, unformattedCursor) +
          value +
          currentText.substring(unformattedCursor);
      _updateTextField(newText, unformattedCursor + 1);
    }
  }

  void _onBackspace() {
    final String formattedText = _amountController.text;
    final String currentText = formattedText.replaceAll('.', '');
    
    int unformattedCursor = 0;
    if (_cursorPosition >= 0 && _cursorPosition <= formattedText.length) {
      unformattedCursor = formattedText.substring(0, _cursorPosition).replaceAll('.', '').length;
    } else {
      unformattedCursor = currentText.length;
    }

    if (unformattedCursor > 0) {
      final newText = currentText.substring(0, unformattedCursor - 1) +
          currentText.substring(unformattedCursor);
      _updateTextField(newText, unformattedCursor - 1);
    }
  }

  void _updateTextField(String newText, int newCursorPosition) {
    final formattedText = Formatters.formatNumberInput(newText);
    final textBeforeCursor = newText.substring(0, newCursorPosition);
    final formattedBeforeCursor = Formatters.formatNumberInput(textBeforeCursor);
    final adjustedCursor = formattedBeforeCursor.length;

    _amountController.text = formattedText;
    _amountController.selection = TextSelection.collapsed(offset: adjustedCursor);
    setState(() {
      _cursorPosition = adjustedCursor;
    });
  }

  void _cursorLeft() {
    if (_cursorPosition > 0) {
      int newPos = _cursorPosition - 1;
      final text = _amountController.text;
      if (newPos > 0 && newPos < text.length && text[newPos] == '.') {
        newPos--;
      }
      setState(() {
        _amountController.selection = TextSelection.collapsed(offset: newPos);
        _cursorPosition = newPos;
      });
    }
  }

  void _cursorRight() {
    if (_cursorPosition < _amountController.text.length) {
      int newPos = _cursorPosition + 1;
      final text = _amountController.text;
      if (newPos < text.length && text[newPos] == '.') {
        newPos++;
      }
      setState(() {
        _amountController.selection = TextSelection.collapsed(offset: newPos);
        _cursorPosition = newPos;
      });
    }
  }

  void _submit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan masukkan limit yang valid')),
      );
      return;
    }

    if (widget.budgetToEdit != null) {
      final updatedBudget = BudgetItem(
        id: widget.budgetToEdit!.id,
        category: _selectedCategory!,
        limitAmount: amount,
      );
      Provider.of<BudgetProvider>(context, listen: false).updateBudget(updatedBudget);
    } else {
      final newBudget = BudgetItem(
        id: const Uuid().v4(),
        category: _selectedCategory!,
        limitAmount: amount,
      );
      Provider.of<BudgetProvider>(context, listen: false).addBudget(newBudget);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.budgetToEdit != null ? 'Edit Anggaran' : 'Tambah Anggaran',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Kategori', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Pilih kategori...'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _expenseCategories.map((String cName) {
                    final cStyle = Constants.getCategoryStyle(cName);
                    return DropdownMenuItem<String>(
                      value: cName,
                      child: Row(
                        children: [
                          Icon(cStyle['icon'] as IconData, color: cStyle['color'] as Color, size: 20),
                          const SizedBox(width: 8),
                          Text(cName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text('Limit Bulanan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  readOnly: true,
                  showCursor: true,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.blue[50]?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (_showCustomKeyboard)
            SizedBox(
              height: 300,
              child: NumericKeyboard(
                onKeyPressed: _onKeyPressed,
                onBackspace: _onBackspace,
                onSubmit: _submit,
                onCursorLeft: _cursorLeft,
                onCursorRight: _cursorRight,
              ),
            ),
        ],
      ),
    );
  }
}

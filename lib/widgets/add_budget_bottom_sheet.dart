import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_item.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'numeric_keyboard.dart';
import 'modern_input_field.dart';

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
  double _threshold = 80.0;
  int _cursorPosition = 0;
  bool _showCustomKeyboard = true;

  final List<String> _expenseCategories = Constants.expenseCategories;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _selectedCategory = widget.budgetToEdit!.category;
      _threshold = widget.budgetToEdit!.threshold;
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
        threshold: _threshold,
      );
      Provider.of<BudgetProvider>(context, listen: false).updateBudget(updatedBudget);
    } else {
      final newBudget = BudgetItem(
        id: const Uuid().v4(),
        category: _selectedCategory!,
        limitAmount: amount,
        threshold: _threshold,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.budgetToEdit != null ? 'Edit Anggaran' : 'Tambah Anggaran',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 0.5),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori Anggaran', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Colors.grey[800]
                    )
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Pilih kategori...'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), 
                        borderSide: BorderSide(color: Colors.grey[200]!)
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), 
                        borderSide: BorderSide(color: Colors.grey[200]!)
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _expenseCategories.map((String cName) {
                      final cStyle = Constants.getCategoryStyle(cName);
                      return DropdownMenuItem<String>(
                        value: cName,
                        child: Row(
                          children: [
                            FaIcon(cStyle['icon'], color: cStyle['color'] as Color, size: 20),
                            const SizedBox(width: 12),
                            Text(cName, style: const TextStyle(fontSize: 15)),
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
                  const SizedBox(height: 24),
                  Text(
                    'Limit Bulanan', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Colors.grey[800]
                    )
                  ),
                  const SizedBox(height: 12),
                  ModernInputField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    hintText: "0",
                    icon: Icons.account_balance_wallet_rounded,
                    readOnly: true,
                    prefixText: "Rp ",
                    onTap: () {
                      setState(() {
                        _showCustomKeyboard = true;
                        _cursorPosition = _amountController.selection.baseOffset;
                        if (_cursorPosition < 0) _cursorPosition = _amountController.text.length;
                      });
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ambang Peringatan', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Colors.grey[800]
                    )
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _threshold,
                          min: 50,
                          max: 100,
                          divisions: 10,
                          label: '${_threshold.toInt()}%',
                          onChanged: (val) => setState(() => _threshold = val),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${_threshold.toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Notifikasi akan dikirim saat pengeluaran mencapai ${_threshold.toInt()}%, 100%, dan 120%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ),
           
          if (_showCustomKeyboard) ...[
            const Divider(height: 1, thickness: 0.5),
            Container(
              height: 280,
              color: Colors.white,
              child: NumericKeyboard(
                onKeyPressed: _onKeyPressed,
                onBackspace: _onBackspace,
                onSubmit: _submit,
                onCursorLeft: _cursorLeft,
                onCursorRight: _cursorRight,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ],
      ),
    );
  }
}

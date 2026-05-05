import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/plan_provider.dart';
import '../utils/formartters.dart';
import 'numeric_keyboard.dart';
import 'modern_input_field.dart';

class AddFundBottomSheet extends StatefulWidget {
  final PlanItem plan;

  const AddFundBottomSheet({super.key, required this.plan});

  @override
  State<AddFundBottomSheet> createState() => _AddFundBottomSheetState();
}

class _AddFundBottomSheetState extends State<AddFundBottomSheet> {
  final _amountController = TextEditingController();
  int _cursorPosition = 0;

  @override
  void dispose() {
    _amountController.dispose();
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
    if (amount > 0) {
      Provider.of<PlanProvider>(context, listen: false).addFundToPlan(widget.plan.id, amount);
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              children: [
                Text(
                  'Tambah Tabungan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.plan.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                
                ModernInputField(
                  controller: _amountController,
                  hintText: "0",
                  icon: Icons.account_balance_wallet_rounded,
                  readOnly: true,
                  prefixText: "Rp ",
                  onTap: () {
                     _cursorPosition = _amountController.selection.baseOffset;
                     if (_cursorPosition < 0) _cursorPosition = _amountController.text.length;
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.5),
          
          // Numeric Keyboard
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../utils/formatters.dart';
import '../utils/numeric_input_controller.dart';
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
  late final NumericInputController _numericInput;

  @override
  void initState() {
    super.initState();
    _numericInput = NumericInputController(controller: _amountController);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _numericInput.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    _numericInput.handleKeyPress(value);
  }

  void _onBackspace() {
    _numericInput.handleBackspace();
  }

  void _cursorLeft() {
    if (_numericInput.cursorPosition > 0) {
      int newPos = _numericInput.cursorPosition - 1;
      final text = _amountController.text;
      if (newPos > 0 && newPos < text.length && text[newPos] == '.') {
        newPos--;
      }
      _amountController.selection = TextSelection.collapsed(offset: newPos);
      _numericInput.cursorPosition = newPos;
      setState(() {});
    }
  }

  void _cursorRight() {
    if (_numericInput.cursorPosition < _amountController.text.length) {
      int newPos = _numericInput.cursorPosition + 1;
      final text = _amountController.text;
      if (newPos < text.length && text[newPos] == '.') {
        newPos++;
      }
      _amountController.selection = TextSelection.collapsed(offset: newPos);
      _numericInput.cursorPosition = newPos;
      setState(() {});
    }
  }

  void _addShortcut(double amount) {
    if (amount <= 0) return;
    setState(() {
      final current = Formatters.parseFormattedNumber(_amountController.text);
      final newAmount = current + amount;
      _amountController.text = Formatters.formatNumberInput(newAmount.toInt().toString());
      _numericInput.updateCursorPosition();
    });
  }

  void _submit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount > 0) {
      Provider.of<PlanProvider>(context, listen: false).addFundToPlan(widget.plan.id, amount);
      Provider.of<ExpenseProvider>(context, listen: false).addSavingsAllocation(
        amount: amount,
        planTitle: widget.plan.title,
      );
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
                    color: Theme.of(context).primaryColor,
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
                     _numericInput.cursorPosition = _amountController.selection.baseOffset;
                     if (_numericInput.cursorPosition < 0) _numericInput.cursorPosition = _amountController.text.length;
                  },
                ),
                const SizedBox(height: 16),

                // Shortcut Pills
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildShortcutBtn(50000, '+50rb'),
                      _buildShortcutBtn(100000, '+100rb'),
                      _buildShortcutBtn(500000, '+500rb'),
                      _buildShortcutBtn(1000000, '+1jt'),
                      _buildShortcutBtn(widget.plan.targetAmount - widget.plan.currentAmount, 'Lunasi Target'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
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

  Widget _buildShortcutBtn(double amount, String label) {
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _addShortcut(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

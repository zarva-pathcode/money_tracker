import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/expense_provider.dart';
import '../providers/plan_provider.dart';
import '../utils/formatters.dart';
import '../utils/numeric_input_controller.dart';
import 'numeric_keyboard.dart';
import 'modern_input_field.dart';

class WithdrawFundBottomSheet extends StatefulWidget {
  final PlanItem plan;

  const WithdrawFundBottomSheet({super.key, required this.plan});

  @override
  State<WithdrawFundBottomSheet> createState() => _WithdrawFundBottomSheetState();
}

class _WithdrawFundBottomSheetState extends State<WithdrawFundBottomSheet> {
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
    setState(() {
      final current = Formatters.parseFormattedNumber(_amountController.text);
      final total = current + amount;
      if (total <= widget.plan.currentAmount) {
        _amountController.text = Formatters.formatNumberInput(total.toInt().toString());
        _numericInput.updateCursorPosition();
      }
    });
  }

  void _submit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }
    if (amount > widget.plan.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah melebihi saldo tabungan')),
      );
      return;
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    expenseProvider.withdrawSavingsAllocation(
      amount: amount,
      planTitle: widget.plan.title,
    );
    planProvider.withdrawFromPlan(widget.plan.id, amount);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${widget.plan.title}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Saldo: ${NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ').format(widget.plan.currentAmount)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ModernInputField(
                  controller: _amountController,
                  hintText: 'Berapa besar nominalnya?',
                  icon: Icons.remove_circle_outline,
                  prefixText: "Rp ",
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // Shortcut pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildShortcutBtn(50000, '+50 rb'),
                      const SizedBox(width: 8),
                      _buildShortcutBtn(100000, '+100 rb'),
                      const SizedBox(width: 8),
                      _buildShortcutBtn(500000, '+500 rb'),
                      const SizedBox(width: 8),
                      _buildShortcutBtn(widget.plan.currentAmount, 'Tarik Semua'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildShortcutBtn(double amount, String label) {
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _addShortcut(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.red,
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

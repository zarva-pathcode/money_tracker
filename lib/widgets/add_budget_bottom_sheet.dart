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
  String _granularity = 'monthly'; // 'daily', 'weekly', 'monthly'
  int _cursorPosition = 0;
  bool _showCustomKeyboard = true; // default terbuka di awal

  final List<String> _expenseCategories = Constants.expenseCategories;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _selectedCategory = widget.budgetToEdit!.category;
      _threshold = widget.budgetToEdit!.threshold;
      _granularity = widget.budgetToEdit!.granularity;
      // If daily or weekly, display base input if preferred or display limitAmount
      final limit = widget.budgetToEdit!.limitAmount;
      double displayAmount = limit;
      if (_granularity == 'daily') displayAmount = limit / 30;
      if (_granularity == 'weekly') displayAmount = limit / 4;
      _amountController.text = Formatters.formatNumberInput(displayAmount.toInt().toString());
    } else {
      _amountController.text = '';
      _selectedCategory = _expenseCategories.isNotEmpty ? _expenseCategories.first : null;
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
    if (!_amountFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
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
    if (!_amountFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    }
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
    final rawInput = Formatters.parseFormattedNumber(_amountController.text);
    if (rawInput <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan atur jumlah nominal lebih dari 0')),
      );
      return;
    }

    double finalLimit = rawInput;
    if (_granularity == 'daily') {
      finalLimit = rawInput * 30; // approx
    } else if (_granularity == 'weekly') {
      finalLimit = rawInput * 4.2857; // ~30/7
    }

    if (widget.budgetToEdit != null) {
      final updatedBudget = BudgetItem(
        id: widget.budgetToEdit!.id,
        category: _selectedCategory!,
        limitAmount: finalLimit,
        threshold: _threshold,
        granularity: _granularity,
      );
      Provider.of<BudgetProvider>(context, listen: false).updateBudget(updatedBudget);
    } else {
      final newBudget = BudgetItem(
        id: const Uuid().v4(),
        category: _selectedCategory!,
        limitAmount: finalLimit,
        threshold: _threshold,
        granularity: _granularity,
      );
      Provider.of<BudgetProvider>(context, listen: false).addBudget(newBudget);
    }

    Navigator.pop(context);
  }

  Widget _buildGranularityChip(String value, String label) {
    final isSelected = _granularity == value;
    final primaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _granularity = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdShortcut(double value) {
    final isSelected = _threshold == value;
    return GestureDetector(
      onTap: () => setState(() => _threshold = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!),
        ),
        child: Text(
          '${value.toInt()}%',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.budgetToEdit != null ? 'Edit Anggaran' : 'Tambah Anggaran Baru',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KATEGORI HORIZONTAL CHIPS ---
                  Text(
                    'Kategori', 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[600])
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.35,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: _expenseCategories.length,
                      itemBuilder: (context, index) {
                        final cName = _expenseCategories[index];
                        final cStyle = Constants.getCategoryStyle(cName);
                        final isSelected = _selectedCategory == cName;
                        final baseColor = cStyle['color'] as Color;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedCategory = cName);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? baseColor.withValues(alpha: 0.15) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? baseColor : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(cStyle['icon'], color: baseColor, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.black87 : Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- TIPE TARGET (GRANULARITAS) ---
                  Text(
                    'Periode Anggaran', 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[600])
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildGranularityChip('daily', 'Harian'),
                      const SizedBox(width: 8),
                      _buildGranularityChip('weekly', 'Mingguan'),
                      const SizedBox(width: 8),
                      _buildGranularityChip('monthly', 'Bulanan'),
                    ],
                  ),
                  
                  const SizedBox(height: 28),

                  // --- INPUT NOMINAL HERO ---
                  Text(
                    _granularity == 'daily'
                        ? 'Nominal per Hari'
                        : (_granularity == 'weekly' ? 'Nominal per Minggu' : 'Nominal Anggaran Bulanan'), 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[600])
                  ),
                  const SizedBox(height: 12),
                  ModernInputField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    hintText: "0",
                    icon: Icons.account_balance_wallet,
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
                  
                  // -- PREVIEW TOTAL BULANAN (JIKA HARIAN/MINGGUAN) --
                  Builder(
                    builder: (context) {
                      final rawInput = Formatters.parseFormattedNumber(_amountController.text);
                      if (rawInput <= 0) return const SizedBox.shrink();

                      String textPreview = '';
                      if (_granularity == 'daily') {
                        final estMonthly = rawInput * 30;
                        textPreview = 'Batas pengeluaran sebulan menjadi ~${Formatters.formatRupiah(estMonthly)}';
                      } else if (_granularity == 'weekly') {
                        final estMonthly = rawInput * 4.2857;
                        textPreview = 'Batas pengeluaran sebulan menjadi ~${Formatters.formatRupiah(estMonthly)}';
                      } else {
                        final dailyEst = rawInput / 30;
                        textPreview = 'Setara pengeluaran ~${Formatters.formatRupiah(dailyEst)} / hari';
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                textPreview,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // --- THRESHOLD SLIDER & SHORTCUTS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Peringatan Mendekati Limit', 
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[600])
                      ),
                      Text(
                        '${_threshold.toInt()}%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildThresholdShortcut(70.0),
                      _buildThresholdShortcut(80.0),
                      _buildThresholdShortcut(90.0),
                      _buildThresholdShortcut(100.0),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _threshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey[200],
                    onChanged: (val) => setState(() => _threshold = val),
                  ),

                  const SizedBox(height: 24),

                  // --- BUTTON SIMPAN (VISIBLE CTA) ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Simpan Anggaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
           
          // Numeric Keyboard Widget
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
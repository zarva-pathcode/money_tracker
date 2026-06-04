import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:money_tracker/utils/formatters.dart';
import 'package:money_tracker/utils/numeric_input_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/plan_item.dart';
import '../providers/plan_provider.dart';
import '../utils/constants.dart';
import '../widgets/numeric_keyboard.dart';
import '../widgets/modern_input_field.dart';

class AddPlanScreen extends StatefulWidget {
  final PlanItem? planToEdit;

  const AddPlanScreen({super.key, this.planToEdit});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialAmountController = TextEditingController();
  late final NumericInputController _targetNumeric;
  late final NumericInputController _initialNumeric;

  final _titleFocusNode = FocusNode();
  final _targetAmountFocusNode = FocusNode();
  final _initialAmountFocusNode = FocusNode();

  bool _showCustomKeyboard = false;
  NumericInputController? _activeNumeric;

  Color _selectedColor = Colors.blue;
  dynamic _selectedIcon = FontAwesomeIcons.house;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  final List<dynamic> _iconOptions = Constants.planIcons;

  NumericInputController get _effectiveNumeric =>
      _activeNumeric ?? _targetNumeric;

  @override
  void initState() {
    super.initState();
    _targetNumeric = NumericInputController(controller: _targetAmountController);
    _initialNumeric = NumericInputController(controller: _initialAmountController);

    if (widget.planToEdit != null) {
      _titleController.text = widget.planToEdit!.title;
      _targetAmountController.text = Formatters.formatNumberInput(
        widget.planToEdit!.targetAmount.toInt().toString(),
      );
      _selectedColor = Color(widget.planToEdit!.colorValue);
      _selectedIcon = Constants.getPlanIcon(widget.planToEdit!.iconCodePoint);
    }

    // Listeners to manage custom keyboard visibility and active controller
    _targetAmountFocusNode.addListener(() {
      if (_targetAmountFocusNode.hasFocus) {
        setState(() {
          _showCustomKeyboard = true;
          _activeNumeric = _targetNumeric;
          _targetNumeric.cursorPosition =
              _targetAmountController.selection.baseOffset;
          if (_targetNumeric.cursorPosition < 0)
            _targetNumeric.cursorPosition = _targetAmountController.text.length;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _initialAmountFocusNode.addListener(() {
      if (_initialAmountFocusNode.hasFocus) {
        setState(() {
          _showCustomKeyboard = true;
          _activeNumeric = _initialNumeric;
          _initialNumeric.cursorPosition =
              _initialAmountController.selection.baseOffset;
          if (_initialNumeric.cursorPosition < 0)
            _initialNumeric.cursorPosition = _initialAmountController.text.length;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = false);
      }
    });

    _targetAmountController.addListener(() {
      if (_activeNumeric == _targetNumeric) {
        _targetNumeric.updateCursorPosition();
      }
    });

    _initialAmountController.addListener(() {
      if (_activeNumeric == _initialNumeric) {
        _initialNumeric.updateCursorPosition();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_titleFocusNode);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    _targetNumeric.dispose();
    _initialNumeric.dispose();
    _titleFocusNode.dispose();
    _targetAmountFocusNode.dispose();
    _initialAmountFocusNode.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    _effectiveNumeric.handleKeyPress(value);
  }

  void _onBackspace() {
    _effectiveNumeric.handleBackspace();
  }

  void _handleKeyboardSubmit() {
    if (_activeNumeric == _targetNumeric) {
      FocusScope.of(context).requestFocus(_initialAmountFocusNode);
    } else if (_activeNumeric == _initialNumeric) {
      setState(() => _showCustomKeyboard = false);
      FocusScope.of(context).unfocus();
    }
  }

  void _cursorLeft() {
    final nc = _activeNumeric;
    if (nc == null || nc.cursorPosition <= 0) return;
    int newPos = nc.cursorPosition - 1;
    final text = nc.controller.text;
    if (newPos > 0 && newPos < text.length && text[newPos] == '.') {
      newPos--;
    }
    nc.controller.selection = TextSelection.collapsed(offset: newPos);
    nc.cursorPosition = newPos;
    setState(() {});
  }

  void _cursorRight() {
    final nc = _activeNumeric;
    if (nc == null || nc.cursorPosition >= nc.controller.text.length) return;
    int newPos = nc.cursorPosition + 1;
    final text = nc.controller.text;
    if (newPos < text.length && text[newPos] == '.') {
      newPos++;
    }
    nc.controller.selection = TextSelection.collapsed(offset: newPos);
    nc.cursorPosition = newPos;
    setState(() {});
  }

  void _savePlan() {
    final title = _titleController.text.trim();
    final targetAmount = Formatters.parseFormattedNumber(
      _targetAmountController.text,
    );

    // Fallback if initial amount is hidden during edit
    final initialAmountText = _initialAmountController.text.trim();
    final initialAmount =
        initialAmountText.isNotEmpty
            ? Formatters.parseFormattedNumber(initialAmountText)
            : 0.0;

    if (title.isEmpty || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan Target (lebih dari 0) harus diisi'),
        ),
      );
      return;
    }

    if (widget.planToEdit != null) {
      final updatedPlan = PlanItem(
        id: widget.planToEdit!.id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: widget.planToEdit!.currentAmount,
        colorValue: _selectedColor.value,
        iconCodePoint: _selectedIcon.codePoint,
      );
      Provider.of<PlanProvider>(context, listen: false).updatePlan(updatedPlan);
    } else {
      final newPlan = PlanItem(
        id: const Uuid().v4(),
        title: title,
        targetAmount: targetAmount,
        currentAmount: initialAmount,
        colorValue: _selectedColor.value,
        iconCodePoint: _selectedIcon.codePoint,
      );
      Provider.of<PlanProvider>(context, listen: false).addPlan(newPlan);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.planToEdit != null ? 'Edit Target' : 'Target Baru',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text(
              "Simpan",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Selector
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FaIcon(
                          _selectedIcon,
                          size: 48,
                          color: _selectedColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  ModernInputField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    hintText: 'Untuk apa tabungan ini?',
                    icon: Icons.edit,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(
                        context,
                      ).requestFocus(_targetAmountFocusNode);
                    },
                  ),
                  const SizedBox(height: 24),

                  ModernInputField(
                    controller: _targetAmountController,
                    focusNode: _targetAmountFocusNode,
                    hintText: 'Berapa target nominalnya?',
                    icon: Icons.flag,
                    prefixText: "Rp ",
                    readOnly: true,
                    onTap: () {
                      setState(() {
                        _showCustomKeyboard = true;
                        _activeNumeric = _targetNumeric;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  if (widget.planToEdit == null) ...[
                    ModernInputField(
                      controller: _initialAmountController,
                      focusNode: _initialAmountFocusNode,
                      hintText: 'Uang terkumpul (Opsional)',
                      icon: Icons.account_balance_wallet,
                      prefixText: "Rp ",
                      readOnly: true,
                      onTap: () {
                        setState(() {
                          _showCustomKeyboard = true;
                          _activeNumeric = _initialNumeric;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Color Picker
                  const Text(
                    'Pilih Warna',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        _colorOptions.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.black87,
                                          width: 3,
                                        )
                                        : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Icon Picker
                  const Text(
                    'Pilih Ikon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children:
                        _iconOptions.map((icon) {
                          final isSelected = _selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? _selectedColor.withOpacity(0.2)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: _selectedColor,
                                          width: 2,
                                        )
                                        : Border.all(
                                          color: Colors.transparent,
                                          width: 2,
                                        ),
                              ),
                              child: FaIcon(
                                icon,
                                color:
                                    isSelected
                                        ? _selectedColor
                                        : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Numeric Keyboard Area
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _showCustomKeyboard ? 300 : 0,
            child: Wrap(
              children: [
                if (_showCustomKeyboard)
                  SizedBox(
                    height: 300,
                    child: NumericKeyboard(
                      onKeyPressed: _onKeyPressed,
                      onBackspace: _onBackspace,
                      onSubmit: _handleKeyboardSubmit,
                      onCursorLeft: _cursorLeft,
                      onCursorRight: _cursorRight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

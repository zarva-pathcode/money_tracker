import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/formartters.dart';
import '../widgets/numeric_keyboard.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? preSelectedCategory;

  const AddExpenseScreen({super.key, this.preSelectedCategory});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();

  // Focus Nodes untuk mengatur perpindahan kursor
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  bool _showCustomKeyboard =
      true; // Default true agar langsung muncul saat dibuka
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedCategory != null) {
      _selectedCategory = widget.preSelectedCategory!;
    }

    // Listener: Jika Title (System Keyboard) aktif, sembunyikan Custom Keyboard
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = false);
      }
    });

    // Listener: Jika Amount diklik, tampilkan Custom Keyboard
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        setState(() => _showCustomKeyboard = true);
        // Tutup system keyboard jika sedang terbuka
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _amountController.addListener(_updateCursorPosition);

    // Auto focus ke amount saat layar dibuka pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  // --- LOGIKA SMART NAVIGATION (INTI PERUBAHAN) ---

  // 1. Aksi Tombol "Centang" di Custom Keyboard
  void _handleKeyboardSubmit() {
    final amount = Formatters.parseFormattedNumber(_amountController.text);

    if (amount > 0) {
      // Jika nominal sudah terisi, pindah ke Catatan (Buka System Keyboard)
      setState(() => _showCustomKeyboard = false);
      FocusScope.of(context).requestFocus(_titleFocusNode);
    } else {
      // Jika kosong, beri peringatan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nominal pengeluaran dulu"),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  // 2. Aksi Tombol "Done/Selesai" di System Keyboard (Field Catatan)
  void _onTitleSubmitted(String value) {
    final amount = Formatters.parseFormattedNumber(_amountController.text);

    if (amount <= 0) {
      // Jika nominal masih kosong, lempar balik ke Amount (Buka Custom Keyboard)
      FocusScope.of(context).unfocus(); // Tutup system keyboard
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_amountFocusNode);
        setState(() => _showCustomKeyboard = true);
      });
    } else {
      // Jika semua lengkap, SIMPAN!
      _saveExpense();
    }
  }

  // --- LOGIKA TEXT FIELD HELPER ---

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
      // AppBar Bersih (Tanpa tombol simpan di atas)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Pengeluaran',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      // Menggunakan Column untuk membagi area Scroll dan Area Bawah (Sticky)
      body: Column(
        children: [
          // 1. AREA SCROLLABLE (Form Input)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Input Nominal (Hero)
                    const Text(
                      "Masukkan Nominal",
                      style: TextStyle(color: Colors.grey),
                    ),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        showCursor: true,
                        readOnly: true, // Agar keyboard system tidak muncul
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

                    // Row: Date & Note
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
                              textInputAction:
                                  TextInputAction
                                      .done, // Tombol "Centang" di keyboard hp
                              onFieldSubmitted:
                                  _onTitleSubmitted, // Panggil logic navigasi
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

                    // Category Grid
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Pilih Kategori",
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

          // 2. TOMBOL SIMPAN (STICKY DI BAWAH)
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
              // Jika keyboard muncul: padding bawah 12 (standar).
              // Jika keyboard tutup: padding bawah 12 + Safe Area (agar tidak nempel garis HP).
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
                "Simpan Pengeluaran",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 3. CUSTOM KEYBOARD (SLIDING UP)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // PERBAIKAN 1: Tinggi keyboard ditambah padding bawah HP
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

                          // Keyboard mengisi sisa ruang
                          Expanded(
                            child: NumericKeyboard(
                              onKeyPressed: _handleKeyPress,
                              onBackspace: _handleBackspace,
                              onSubmit: _handleKeyboardSubmit,
                            ),
                          ),

                          // PERBAIKAN 2: Spacer untuk area aman (Home Indicator)
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).addExpense(newExpense).then((_) => Navigator.pop(context));
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/image_preprocessor.dart';
import '../utils/receipt_parser.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  File? _image;
  bool _isProcessing = false;
  String _processingMessage = "";
  String _ocrTextForDebug = ""; // can be used to show raw OCR text if needed

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String _selectedCategory = Constants.expenseCategories.first; // Default
  DateTime _selectedDate = DateTime.now();

  late DocumentScanner _documentScanner;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  void initState() {
    super.initState();
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.filter, // Mengizinkan user edit/crop
        pageLimit: 1,
        isGalleryImport: true,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _textRecognizer.close();
    _documentScanner.close();
    super.dispose();
  }

  Future<void> _startScanSequence() async {
    try {
      // Step 1: Scan Document (Auto-crop & Edge Detection)
      setState(() {
        _isProcessing = true;
        _processingMessage = "Mendeteksi tepi struk...";
      });

      final DocumentScanningResult response = await _documentScanner.scanDocument();
      final List<String> images = response.images ?? [];

      if (images.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final String scannedPath = images.first;
      setState(() {
        _image = File(scannedPath);
        _processingMessage = "Menjernihkan struk...";
      });

      // Step 2: OpenCV Preprocessing (ImagePreprocessor)
      final String processedPath = await ImagePreprocessor.processReceiptImage(scannedPath);
      setState(() {
        _image = File(processedPath);
        _processingMessage = "Membaca teks struk...";
      });

      // Step 3: Text Recognition (ML Kit)
      final inputImage = InputImage.fromFilePath(processedPath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Step 4: Smart Parsing (ReceiptParser)
      setState(() {
        _processingMessage = "Menganalisis total belanja...";
      });

      double extractedTotal = _parseTotalFromReceipt(recognizedText);

      setState(() {
        if (extractedTotal > 0) {
          _amountController.text = extractedTotal.toInt().toString();
        }
        _ocrTextForDebug = recognizedText.text;
        _isProcessing = false;
        _processingMessage = "";
      });
    } catch (e) {
      debugPrint("Scan Sequence Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses struk: $e')),
      );
      setState(() {
        _isProcessing = false;
        _processingMessage = "";
      });
    }
  }

  // --- OCR PARSING HEURISTICS ---
  double _parseTotalFromReceipt(RecognizedText recognizedText) {
    // Kumpulkan baris teks dari blok OCR
    List<String> rawLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        rawLines.add(line.text);
      }
    }

    // Panggil helper yang sudah mengimplementasikan decision tree berlapis
    return ReceiptParser.extractTotal(rawLines) ?? 0.0;
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak boleh kosong')),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title:
          _titleController.text.isEmpty
              ? "Belanja Struk"
              : _titleController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: 'expense',
    );

    Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
    Navigator.pop(context);
  }

  // --- UI BUILDING ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showImageSourceActionSheet() {
    // Fungsi ini tidak lagi diperlukan karena DocumentScanner memiliki UI lengkap
    // namun kita biarkan kosong atau hapus panggilannya di UI.
    _startScanSequence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Scan Struk',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE PREVIEW AREA
            GestureDetector(
              onTap: _showImageSourceActionSheet,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    _isProcessing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                _processingMessage,
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : _image != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Colors.blue[300],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Tap untuk foto/pilih struk",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 30),

            // FORM AREA
            const Text(
              "Total Belanja",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  hintText: '0',
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Judul Transaksi",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Misal: Makan Siang McD',
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Kategori",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items:
                      Constants.expenseCategories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Tanggal",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // SUBMIT BUTTON
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Simpan Transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

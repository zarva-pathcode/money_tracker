import 'dart:io';
import 'package:flutter/material.dart';
import 'package:money_tracker/screens/add_expense_screen.dart';
import '../services/ocr_service.dart';
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
  String _rawOcrText = "";
  double? _detectedTotal;
  String? _errorMessage;

  Future<void> _startScanSequence() async {
    try {
      // 1. Ambil Gambar Struk
      final scannedPath = await OcrService.scanDocument();
      if (scannedPath == null) return;

      if (!mounted) return;
      setState(() {
        _image = File(scannedPath);
        _isProcessing = true;
        _processingMessage = "Membaca teks struk...";
        _errorMessage = null;
      });

      // 2. Ekstraksi Teks (3-pass otomatis)
      final rawText = await OcrService.extractText(scannedPath);

      // 3. Parsing total
      final total = ReceiptParser.parseFromRawText(rawText);

      if (!mounted) return;
      setState(() {
        _rawOcrText = rawText;
        _detectedTotal = total;
        _isProcessing = false;
        _processingMessage = "";
        if (rawText.isEmpty) {
          _errorMessage = "Tidak ada teks terbaca. Coba scan ulang dengan pencahayaan lebih baik.";
        } else if (total == null) {
          _errorMessage = "Teks terbaca tapi tidak dapat mendeteksi total. Lihat teks OCR di bawah dan edit manual.";
        }
      });
    } catch (e) {
      debugPrint("Scan Sequence Error: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingMessage = "";
          _errorMessage = "Gagal memproses struk: $e";
        });
      }
    }
  }

  void _proceedWithAmount(double? amount) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          preSelectedCategory: null,
          initialTransactionType: 'expense',
          preFilledAmount: amount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Smart Receipt Scanner',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isProcessing) ...[
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      "Memproses gambar...",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ] else if (_image == null) ...[
              _buildInitialView(),
            ] else ...[
              _buildResultView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.document_scanner_rounded, size: 80,
              color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 32),
        const Text(
          "Scan Struk Belanja",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Posisikan struk di area terang agar teks terbaca jelas.\n"
          "Hasil scan bisa diedit manual jika kurang akurat.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startScanSequence,
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            label: const Text(
              "Mulai Scan",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview gambar
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Text("Gambar tidak tersedia")),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Hasil deteksi total
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Detected amount
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Terdeteksi",
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _detectedTotal != null
                        ? "Rp ${_detectedTotal!.toInt()}"
                        : "Rp 0",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _detectedTotal != null
                          ? Theme.of(context).primaryColor
                          : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  if (_detectedTotal != null)
                    const Icon(Icons.check_circle, color: Colors.green, size: 28),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startScanSequence,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Scan Ulang"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _proceedWithAmount(null),
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                label: const Text(
                  "Isi Manual",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_detectedTotal != null) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _proceedWithAmount(_detectedTotal),
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text(
                    "Gunakan",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Raw OCR text untuk debugging
        if (_rawOcrText.isNotEmpty) ...[
          const Text(
            "Teks OCR Mentah",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: SelectableText(
              _rawOcrText,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Tips: Struk thermal yang sudah lama atau kusut sulit terbaca. "
                  "Gunakan pencahayaan cukup dan posisi struk rata untuk hasil terbaik.",
                  style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

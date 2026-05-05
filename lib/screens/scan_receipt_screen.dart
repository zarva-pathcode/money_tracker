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

  Future<void> _startScanSequence() async {
    try {
      // 1. Ambil Gambar Struk (ScannerMode.filter menjernihkan teks otomatis)
      final String? scannedPath = await OcrService.scanDocument();
      
      if (scannedPath == null) return;

      setState(() {
        _image = File(scannedPath);
        _isProcessing = true;
        _processingMessage = "Membaca teks struk...";
      });

      // 2. Ekstraksi Teks (ML Kit Recognition)
      final String rawText = await OcrService.extractText(scannedPath);

      setState(() {
        _processingMessage = "Menganalisis total belanja...";
      });

      // 3. Smart Parsing (ReceiptParser)
      final double? extractedTotal = ReceiptParser.parseFromRawText(rawText);

      setState(() {
        _isProcessing = false;
        _processingMessage = "";
      });

      // 4. Navigasi Otomatis ke AddExpenseScreen dengan pre-filled nominal
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(
              preSelectedCategory: null, // User bisa pilih nanti
              initialTransactionType: 'expense',
              preFilledAmount: extractedTotal,
            ),
          ),
        );
        
        // Opsional: Tampilkan feedback jika nominal ditemukan
        if (extractedTotal != null && extractedTotal > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Total terdeteksi: Rp ${extractedTotal.toInt()}"),
              backgroundColor: Colors.green,
            ),
          );
          // Catatan: Jika AddExpenseScreen belum mendukung pre-filled amount via constructor,
          // kita bisa menambahkannya di sana.
        }
      }
    } catch (e) {
      debugPrint("Scan Sequence Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses struk: $e')),
        );
        setState(() {
          _isProcessing = false;
          _processingMessage = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Smart Receipt Scanner',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _processingMessage,
                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.document_scanner_rounded, size: 80, color: Colors.blue[600]),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Scan Struk Belanja",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Posisikan struk di area terang agar teks terbaca dengan jelas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startScanSequence,
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text("Mulai Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

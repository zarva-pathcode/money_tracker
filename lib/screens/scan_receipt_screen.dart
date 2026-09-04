import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/screens/add_expense_screen.dart';
import '../services/ocr_service.dart';
import '../utils/receipt_parser.dart';

class ScanReceiptScreen extends StatefulWidget {
  /// Path gambar hasil scan langsung (alur cepat dari modal).
  /// Jika null, tampilkan halaman awal dengan tombol scan manual.
  final String? initialImagePath;

  const ScanReceiptScreen({super.key, this.initialImagePath});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  File? _image;
  bool _isProcessing = false;
  String _rawOcrText = "";
  double? _detectedTotal;
  String? _errorMessage;
  final _amountController = TextEditingController();
  bool _editingAmount = false;

  @override
  void initState() {
    super.initState();
    // Alur cepat: gambar sudah ada → set state proses sejak frame pertama
    // (tanpa kedip tampilan awal), lalu jalankan AI setelah layout siap.
    if (widget.initialImagePath != null) {
      _image = File(widget.initialImagePath!);
      _isProcessing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processImage(widget.initialImagePath!);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Alur manual (fallback): buka kamera dulu, lalu proses hasilnya.
  Future<void> _startScanSequence() async {
    final scannedPath = await OcrService.scanDocument();
    if (scannedPath == null || !mounted) return;
    _processImage(scannedPath);
  }

  /// Proses AI: ekstraksi teks + parsing total dari path gambar.
  Future<void> _processImage(String imagePath) async {
    try {
      setState(() {
        _image = File(imagePath);
        _isProcessing = true;
        _errorMessage = null;
        _detectedTotal = null;
        _rawOcrText = "";
      });

      // Ekstraksi Teks (multi-pass otomatis)
      final rawText = await OcrService.extractText(imagePath);

      // Parsing total
      final total = ReceiptParser.parseFromRawText(rawText);

      if (!mounted) return;
      setState(() {
        _rawOcrText = rawText;
        _detectedTotal = total;
        _isProcessing = false;
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
          preFilledNote: _firstOcrLine(),
        ),
      ),
    );
  }

  /// Baris teks bermakna pertama dari OCR (biasanya nama merchant)
  /// untuk mengisi catatan transaksi otomatis.
  String? _firstOcrLine() {
    for (final line in _rawOcrText.split('\n')) {
      final text = line.trim();
      if (text.length >= 3) {
        return text.length > 40 ? text.substring(0, 40) : text;
      }
    }
    return null;
  }

  /// Confidence badge modern: pill status akurasi AI.
  Widget _buildConfidenceBadge() {
    Color color;
    String label;
    IconData icon;

    if (_errorMessage == null && _detectedTotal != null) {
      color = Colors.green.shade700;
      label = "Akurasi Tinggi";
      icon = Icons.check_circle_rounded;
    } else if (_rawOcrText.isNotEmpty && _detectedTotal == null) {
      color = Colors.orange.shade800;
      label = "Akurasi Sedang";
      icon = Icons.warning_amber_rounded;
    } else {
      color = Colors.red.shade700;
      label = "Perlu Dicek";
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Scan Struk Belanja',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (_isProcessing) ...[
              _buildProcessingView(),
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

  /// Status proses AI dengan ikon radar + pesan informatif.
  Widget _buildProcessingView() {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: primary,
                  backgroundColor: primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.06,
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 28),
          const Text(
            "Membaca struk...",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "AI mengekstrak teks nota & mendeteksi total belanja",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Halaman awal (fallback): hero + panduan + tombol scan.
  Widget _buildInitialView() {
    final primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Hero ilustrasi
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FaIcon(
                  FontAwesomeIcons.fileInvoice,
                  size: 64,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Scan & Ekstrak Struk Otomatis",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Foto nota belanja, total & nama toko terisi sendiri",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOut),
        const SizedBox(height: 24),
        // Kartu panduan scan
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildGuideRow(
                icon: FontAwesomeIcons.lightbulb,
                color: Colors.amber[700]!,
                title: 'Pencahayaan cukup',
                subtitle: 'Pastikan cahaya terang dan tidak berbayang',
              ),
              const SizedBox(height: 14),
              _buildGuideRow(
                icon: FontAwesomeIcons.expand,
                color: Colors.blue[700]!,
                title: 'Posisi struk rata',
                subtitle: 'Ratakan nota agar tepinya terdeteksi sempurna',
              ),
              const SizedBox(height: 14),
              _buildGuideRow(
                icon: FontAwesomeIcons.bolt,
                color: Colors.green[700]!,
                title: 'Otomatis terisi',
                subtitle: 'Total belanja & nama toko diekstrak oleh AI',
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 350.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.1,
              end: 0,
              delay: 100.ms,
              duration: 350.ms,
              curve: Curves.easeOutQuad,
            ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startScanSequence,
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            label: const Text(
              "Mulai Scan Nota",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGuideRow({
    required dynamic icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: FaIcon(icon, color: color, size: 18)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final merchant = _firstOcrLine();
    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu preview foto struk
        if (_image != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
          )
              .animate()
              .fadeIn(duration: 350.ms, curve: Curves.easeOut),
        const SizedBox(height: 16),

        // Peringatan error (jika ada)
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange[800],
                  size: 20,
                ),
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
        ],

        // Kartu hero total + merchant
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Belanja",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildConfidenceBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_editingAmount) ...[
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: primary,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final val = double.tryParse(_amountController.text);
                        if (val != null && val > 0) {
                          setState(() {
                            _detectedTotal = val;
                            _editingAmount = false;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        _detectedTotal != null
                            ? currency.format(_detectedTotal)
                            : "Rp 0",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: _detectedTotal != null
                              ? Colors.black87
                              : Colors.red[600],
                        ),
                      ),
                    ),
                    if (_detectedTotal != null)
                      InkWell(
                        onTap: () {
                          _amountController.text =
                              _detectedTotal!.toInt().toString();
                          setState(() => _editingAmount = true);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              // Nama toko terdeteksi (jadi catatan otomatis)
              if (merchant != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.store,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toko terdeteksi',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              merchant,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Jadi catatan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 80.ms, duration: 350.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.1,
              end: 0,
              delay: 80.ms,
              duration: 350.ms,
              curve: Curves.easeOutQuad,
            ),
        const SizedBox(height: 20),

        // Tombol utama: gunakan & lanjut
        if (_detectedTotal != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _proceedWithAmount(_detectedTotal),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                "Gunakan & Lanjut",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (_detectedTotal != null) const SizedBox(height: 12),

        // Tombol sekunder berdampingan
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startScanSequence,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Scan Ulang"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _proceedWithAmount(null),
                icon: Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: Colors.grey[600],
                ),
                label: Text(
                  "Isi Manual",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Accordion teks OCR mentah
        if (_rawOcrText.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text(
                  "Teks OCR Mentah",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Ketuk untuk memeriksa detail barang',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
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
                ],
              ),
            ),
          ),
        if (_rawOcrText.isNotEmpty) const SizedBox(height: 16),

        // Kartu tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Struk thermal yang sudah lama atau kusut sulit terbaca. "
                  "Gunakan pencahayaan cukup dan posisi struk rata untuk hasil terbaik.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

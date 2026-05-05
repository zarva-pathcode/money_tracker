import 'package:flutter/foundation.dart';

class ReceiptParser {
  /// Mengekstrak total belanja dari teks OCR menggunakan Pipeline 5 Tahap.
  static double? extractTotal(List<String> rawLines) {
    if (rawLines.isEmpty) return null;

    // TAHAP 1: Universal Normalization (Pembersihan Ekstrem)
    List<String> normalizedLines = rawLines.map((line) => _normalizeLine(line)).toList();

    return _processNormalizedLines(normalizedLines);
  }

  /// Helper untuk memproses teks mentah (raw text) langsung dari ML Kit
  static double? parseFromRawText(String text) {
    if (text.isEmpty) return null;
    final lines = text.split('\n');
    return extractTotal(lines);
  }

  static double? _processNormalizedLines(List<String> normalizedLines) {
    // TAHAP 4: Weighted Anchor Search (Pencarian Baris Cerdas)
    // List array berbobot dari prioritas paling tinggi ke rendah
    final List<List<String>> keywordPriorities = [
      ["CASH", "TUNAI", "DEBIT", "KARTU", "QRIS", "CREDIT", "VISA"],   // Prio 1
      ["GRAND TOTAL", "TOTAL BAYAR", "NETTO"],                         // Prio 2
      ["TOTAL", "AMOUNT"],                                             // Prio 3
    ];

    for (List<String> priorityKeywords in keywordPriorities) {
      for (int i = 0; i < normalizedLines.length; i++) {
        final String currentLine = normalizedLines[i];

        // Memeriksa apakah baris ini mengandung kata kunci dari level prioritas saat ini
        bool hasKeyword = priorityKeywords.any((keyword) => currentLine.contains(keyword)) &&
                          !currentLine.contains("SUBTOTAL") &&
                          !currentLine.contains("SUB TOTAL");

        if (hasKeyword) {
          // Kata kunci ditemukan! Cek baris ini dan maksimal 2 baris ke bawahnya
          for (int j = 0; j <= 2; j++) {
            if (i + j < normalizedLines.length) {
              final String searchLine = normalizedLines[i + j];
              // Ekstrak semua format uang yang potensial di baris target
              final List<double> validPrices = _extractValidPricesFromLine(searchLine);
              
              if (validPrices.isNotEmpty) {
                // Biasanya baris pembayaran memiliki harga yang valid (ambil angka terbesarnya jika ada multiple)
                validPrices.sort((a, b) => b.compareTo(a));
                debugPrint("ReceiptParser: PrioMatched '$searchLine' -> ${validPrices.first}");
                return validPrices.first;
              }
            }
          }
        }
      }
    }

    // TAHAP 5: Desperate Fallback (Sapu Jagat Bawah)
    // Mengambil 30% baris terbawah dari kertas (Misal total ada 10 baris, ambil 3 baris terakhir)
    int startIndex = (normalizedLines.length * 0.7).floor();
    List<String> bottomLines = normalizedLines.sublist(startIndex);

    List<double> bottomValidPrices = [];
    for (String line in bottomLines) {
      bottomValidPrices.addAll(_extractValidPricesFromLine(line));
    }

    if (bottomValidPrices.isNotEmpty) {
      // Urutkan menurun dan kembalikan angka nominal yang paling besar
      bottomValidPrices.sort((a, b) => b.compareTo(a));
      debugPrint("ReceiptParser: Fallback Bottom 30% -> ${bottomValidPrices.first}");
      return bottomValidPrices.first;
    }

    debugPrint("ReceiptParser: GAGAL menemukan angka valid");
    return null;
  }

  // ==========================================
  // TAHAP 1: Universal Normalization
  // ==========================================
  static String _normalizeLine(String line) {
    // 1. Ubah ke uppercase
    String cleaned = line.toUpperCase();

    // 2. Koreksi typo OCR (O->0, I->1, l->1, B->8) yang diapit angka
    // Regex mencari karakter-karakter tersebut jika di sekitarnya terdapat angka
    cleaned = cleaned.replaceAllMapped(RegExp(r'\d+[OIQlB]+\d*|\d*[OIQlB]+\d+'), (match) {
      String segment = match.group(0)!;
      segment = segment.replaceAll(RegExp(r'[OQ]'), '0');
      segment = segment.replaceAll(RegExp(r'[Iil]'), '1');
      segment = segment.replaceAll(RegExp(r'[B]'), '8');
      return segment;
    });

    // 3. Bersihkan simbol mata uang pengganggu (RP, IDR)
    // Pakai Regex agar menghapus "RP", "RP.", "IDR", "IDR." secara dinamis
    cleaned = cleaned.replaceAll(RegExp(r'\b(?:RP|IDR)\.?\s*', caseSensitive: false), '');

    return cleaned;
  }

  // ==========================================
  // EXTRACTOR UTAMA (Menghubungkan Tahap 2 & 3)
  // Mengambil semua angka di baris tertentu yang masuk kriteria harga
  // ==========================================
  static List<double> _extractValidPricesFromLine(String line) {
    List<double> foundPrices = [];
    
    // Regex ini menangkap deretan angka yang berpotensi menjadi harga
    // Termasuk yang pakai titik (15.000) koma (15,000.00) atau murni angka rapat (15000)
    final numRegex = RegExp(r'\b\d+(?:[\.,]\d+)*\b');
    
    Iterable<Match> matches = numRegex.allMatches(line);
    for (Match match in matches) {
      String rawExtracted = match.group(0)!;
      double? parsedValue = _parseSmartCurrency(rawExtracted);

      if (parsedValue != null && _isValidPrice(parsedValue, rawExtracted)) {
        foundPrices.add(parsedValue);
      }
    }

    return foundPrices;
  }

  // ==========================================
  // TAHAP 2: Smart Currency Formatter (Mengatasi Titik & Koma)
  // ==========================================
  static double? _parseSmartCurrency(String rawExtracted) {
    String numberStr = rawExtracted;

    // Bersihkan titik atau koma di ujung string jika ada
    numberStr = numberStr.replaceAll(RegExp(r'^[\.,]+|[\.,]+$'), '');
    if (numberStr.isEmpty) return null;

    // Cek apakah ada desimal (sen) 2 karakter di belakang (,00 atau .00)
    // Umum di struk minimarket: 15.000,00 atau 15,000.00
    if (numberStr.length > 3) {
      String lastThree = numberStr.substring(numberStr.length - 3);
      if (lastThree.startsWith(',') || lastThree.startsWith('.')) {
        // Hapus 3 karakter terakhir (pemisah desimal dan 2 angka nol)
        // Karena expense tracker umum tidak mencatat sen
        numberStr = numberStr.substring(0, numberStr.length - 3);
      }
    }

    // Buang semua titik dan koma yang tersisa (yang seharusnya merupakan pemisah ribuan)
    // Mengubah "15.000" atau "15,000" menjadi "15000"
    String finalDigits = numberStr.replaceAll(RegExp(r'[\.,]'), '');

    return double.tryParse(finalDigits);
  }

  // ==========================================
  // TAHAP 3: Filter "Anti-Barcode" (Price Validator)
  // ==========================================
  static bool _isValidPrice(double parsedPrice, String rawExtracted) {
    // 1. Tolak angka yang di luar batas kewajaran Expense harian
    // Struk belanja biasanya antara Rp 500 sampai Rp 50.000.000
    if (parsedPrice < 500 || parsedPrice > 50000000) {
      return false;
    }

    // 2. Tolak deretan digit panjang tanpa pemisah ribuan (Kemungkinan Barcode / PLU barang)
    // Misal: string asal "250043" atau "999905" (tanpa titik koma) dengan digit > 4.
    // Hilangkan kemungkinan desimal, cek panjang string sebelum desimal
    String withoutDecimal = rawExtracted.replaceAll(RegExp(r'[\.,]\d{2}$'), '');
    bool hasNoThousandsSeparator = !withoutDecimal.contains('.') && !withoutDecimal.contains(',');

    // Tolak jika panjang digit tanpa titik/koma >= 6 (misal: 250043, 899990)
    // Angka 15000 (5 digit) masih kita hargai sebagai nominal Rp 15.000 tanpa pemisah
    if (hasNoThousandsSeparator && withoutDecimal.length >= 6) {
      return false;
    }

    return true; // Lolos semua filter pencucian!
  }
}

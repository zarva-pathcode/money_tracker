import 'package:flutter/foundation.dart';

class ReceiptParser {
  static const _minPrice = 200;
  static const _maxPrice = 100000000;

  /// Keyword anchor: original → daftar kemungkinan OCR typo
  static final _keywordVariants = <String, List<String>>{
    'TOTAL': ['TOTAL', 'TOTA1', 'TOTAI', 'T0TAL', 'TOTAl'],
    'GRAND TOTAL': ['GRAND TOTAL', 'GRAND T0TAL', 'GRAND TOTA1'],
    'TOTAL BAYAR': ['TOTAL BAYAR', 'TOTAL BAYA', 'TOTAL BAYAR', 'T0TAL BAYAR'],
    'CASH': ['CASH', 'CASH', 'CA5H', 'C4511'],
    'TUNAI': ['TUNAI', 'TUNA1', 'TUNAI'],
    'DEBIT': ['DEBIT', 'DEB1T', 'DEB1T', 'DE8IT'],
    'KREDIT': ['KREDIT', 'KRED1T'],
    'QRIS': ['QRIS', 'QR1S'],
    'VISA': ['VISA', 'V1SA', 'VI5A'],
    'NETTO': ['NETTO', 'NETT0'],
    'AMOUNT': ['AMOUNT', 'AM0UNT', 'AMOUNT'],
    'SUBTOTAL': ['SUBTOTAL', 'SUBT0TAL', 'SUB T0TAL'],
  };

  /// Ekstrak total belanja dari teks OCR mentah
  static double? parseFromRawText(String text) {
    if (text.isEmpty) return null;
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    return _extractTotal(lines);
  }

  static double? _extractTotal(List<String> rawLines) {
    final normalized = rawLines.map(_normalizeLine).toList();

    // --- Priority search: keyword anchoring ---
    final priorities = [
      ['CASH', 'TUNAI', 'DEBIT', 'KREDIT', 'QRIS', 'VISA'],
      ['GRAND TOTAL', 'TOTAL BAYAR', 'NETTO'],
      ['TOTAL', 'AMOUNT'],
    ];

    for (final group in priorities) {
      for (int i = 0; i < normalized.length; i++) {
        final line = normalized[i];

        final hasKeyword = group.any((kw) => _fuzzyContains(line, kw));
        if (!hasKeyword) continue;
        if (_fuzzyContains(line, 'SUBTOTAL') ||
            _fuzzyContains(line, 'SUB TOTAL')) continue;

        // Cek baris ini, lalu max 3 baris ke bawah
        for (int j = 0; j <= 3 && i + j < normalized.length; j++) {
          final target = normalized[i + j];
          if (target.isEmpty) continue;
          final prices = _extractPrices(target);
          if (prices.isNotEmpty) {
            prices.sort((a, b) => b.compareTo(a));
            debugPrint("ReceiptParser: matched '${target.trim()}' -> ${prices.first}");
            return prices.first;
          }
        }
      }
    }

    // --- Fallback: bottom 40% ambil nominal terbesar ---
    final startIdx = (normalized.length * 0.6).floor();
    final bottom = normalized.sublist(startIdx);
    final allPrices = <double>[];
    for (final line in bottom) {
      allPrices.addAll(_extractPrices(line));
    }
    if (allPrices.isNotEmpty) {
      allPrices.sort((a, b) => b.compareTo(a));
      debugPrint("ReceiptParser: fallback bottom -> ${allPrices.first}");
      return allPrices.first;
    }

    // --- Last resort: seluruh dokumen, ambil nominal terbesar ---
    final allDocPrices = <double>[];
    for (final line in normalized) {
      allDocPrices.addAll(_extractPrices(line));
    }
    if (allDocPrices.isNotEmpty) {
      allDocPrices.sort((a, b) => b.compareTo(a));
      debugPrint("ReceiptParser: last resort -> ${allDocPrices.first}");
      return allDocPrices.first;
    }

    debugPrint("ReceiptParser: GAGAL");
    return null;
  }

  static bool _fuzzyContains(String text, String keyword) {
    final variants = _keywordVariants[keyword] ?? [keyword];
    return variants.any((v) => text.contains(v));
  }

  // ==========================================
  // Normalisasi
  // ==========================================
  static String _normalizeLine(String line) {
    String s = line.toUpperCase().trim();

    // Koreksi OCR typo: sub O/O → 0, I/l → 1, S → 5, B → 8 di konteks angka
    s = s.replaceAllMapped(RegExp(r'[OQ]'), (m) => '0');
    s = s.replaceAllMapped(RegExp(r'[Il]'), (m) => '1');
    s = s.replaceAllMapped(RegExp(r'[B]'), (m) => '8');

    // Bersihkan prefix RP/IDR
    s = s.replaceAll(RegExp(r'\b(?:RP|IDR)\.?\s*'), '');

    return s;
  }

  // ==========================================
  // Ekstraksi harga dari satu baris
  // ==========================================
  static List<double> _extractPrices(String line) {
    final result = <double>[];

    // Format: <digit>{,.\d}* — tangkap semua calon nominal
    final matches = RegExp(r'\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+').allMatches(line);

    for (final m in matches) {
      final raw = m.group(0)!;
      final parsed = _parsePrice(raw);
      if (parsed != null && _isValidPrice(parsed)) {
        result.add(parsed);
      }
    }

    return result;
  }

  static double? _parsePrice(String raw) {
    String s = raw;

    // Buang separator di ujung
    s = s.replaceAll(RegExp(r'^[.,]+|[.,]+$'), '');

    // Deteksi format desimal: 15.000,00 atau 15,000.00
    // 3 digit terakhir dengan pemisah → desimal
    if (s.length > 3) {
      final sep = s[s.length - 3];
      if ((sep == '.' || sep == ',') &&
          RegExp(r'^\d$').hasMatch(s[s.length - 1]) &&
          RegExp(r'^\d$').hasMatch(s[s.length - 2])) {
        s = s.substring(0, s.length - 3);
      }
    }

    // Buang semua separator ribuan (titik/koma)
    s = s.replaceAll(RegExp(r'[.,]'), '');

    return double.tryParse(s);
  }

  static bool _isValidPrice(double value) {
    if (value < _minPrice || value > _maxPrice) {
      return false;
    }
    return true;
  }
}

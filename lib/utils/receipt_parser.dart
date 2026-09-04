import 'package:flutter/foundation.dart';

class ReceiptParser {
  static const _minPrice = 200;
  static const _maxPrice = 100000000;

  /// Keyword anchor: original → daftar kemungkinan OCR typo
  static final _keywordVariants = <String, List<String>>{
    'TOTAL': ['TOTAL', 'TOTA1', 'TOTAI', 'T0TAL', 'TOTAl'],
    'GRAND TOTAL': ['GRAND TOTAL', 'GRAND T0TAL', 'GRAND TOTA1'],
    'GRAND': ['GRAND', 'GRAND'],
    'TOTAL BAYAR': ['TOTAL BAYAR', 'TOTAL BAYA', 'TOTAL BAYAR', 'T0TAL BAYAR'],
    'TOTAL HARGA': ['TOTAL HARGA', 'TOTAL HARGA', 'T0TAL HARGA'],
    'TOTAL BELANJA': ['TOTAL BELANJA', 'TOTAL BELANJA', 'T0TAL BELANJA'],
    'JUMLAH': ['JUMLAH', 'JUMLAH', 'JUML4H'],
    'BAYAR': ['BAYAR', 'BAYAR', 'B4YAR'],
    'KEMBALI': ['KEMBALI', 'KEMBAL1', 'K3MBALI'],
    'NET TOTAL': ['NET TOTAL', 'NET T0TAL', 'N3T TOTAL'],
    'NETTO': ['NETTO', 'NETT0'],
    'AMOUNT': ['AMOUNT', 'AM0UNT', 'AMOUNT'],
    'CASH': ['CASH', 'CASH', 'CA5H', 'C4511'],
    'TUNAI': ['TUNAI', 'TUNA1', 'TUNAI'],
    'DEBIT': ['DEBIT', 'DEB1T', 'DEB1T', 'DE8IT'],
    'KREDIT': ['KREDIT', 'KRED1T'],
    'QRIS': ['QRIS', 'QR1S'],
    'VISA': ['VISA', 'V1SA', 'VI5A'],
    'CHARGE': ['CHARGE', 'CHARG3', 'CHARGE'],
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

        // Cek baris ini, lalu max 5 baris ke bawah (expand window)
        for (int j = 0; j <= 5 && i + j < normalized.length; j++) {
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

    // Koreksi OCR typo context-aware: O→0, I→1, B→8 HANYA jika diapit digit
    // (mis. "0R15.000" → "0R15.000" ok, "INDOMARET" → tetap "INDOMARET")
    s = s.replaceAllMapped(
      RegExp(r'(?<=\d)[OQ](?=\d)'), (m) => '0',
    );
    s = s.replaceAllMapped(
      RegExp(r'(?<=\d)[Il](?=\d)'), (m) => '1',
    );
    s = s.replaceAllMapped(
      RegExp(r'(?<=\d)[B](?=\d)'), (m) => '8',
    );

    // Bersihkan prefix RP/IDR
    s = s.replaceAll(RegExp(r'\b(?:RP|IDR)\.?\s*'), '');

    return s;
  }

  // ==========================================
  // Ekstraksi harga dari satu baris
  // ==========================================
  static List<double> _extractPrices(String line) {
    final result = <double>[];

    // Pattern:1-3 digit + (separator ribuan)xN + optional desimal 2 digit
    // Prioritas: ribuan.detik → ribuan,detik → integer
    // Jangan pakai \d+ fallback karena memecah "32.300" jadi ["32","300"]
    final pricePattern = RegExp(
      r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d{1,3}(?:[.,]\d{3})?|\d{4,}',
    );
    final matches = pricePattern.allMatches(line);

    for (final m in matches) {
      final raw = m.group(0)!;

      // Exclude: barcode >13 digit, timestamp (mengandung ':'), quantity <3 digit tanpa prefix Rp
      if (raw.length > 13) continue;
      if (raw.contains(':')) continue;
      if (raw.length < 3 && !line.contains('Rp')) continue;

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

    // Deteksi format berdasarkan posisi separator TERAKHIR:
    // - "15.000,00" → last sep ',' → Indonesian: ribuan '.', desimal ','
    // - "15,000.00" → last sep '.' → International: ribuan ',', desimal '.'
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    final hasDecimal = (lastDot > lastComma && lastDot != -1) ||
        (lastComma > lastDot && lastComma != -1);
    final sepChar = lastDot > lastComma ? '.' : ',';

    if (hasDecimal) {
      final parts = s.split(sepChar);
      if (parts.length == 2 && parts[1].length <= 2) {
        // Desimal: buang semua ribuan, ganti desimal jadi '.'
        final intPart = parts[0].replaceAll(RegExp(r'[.,]'), '');
        final decPart = parts[1];
        s = '$intPart.$decPart';
      }
    } else {
      // Tidak ada separator → angka bulat
      s = s.replaceAll(RegExp(r'[.,]'), '');
    }

    return double.tryParse(s);
  }

  static bool _isValidPrice(double value) {
    // Exclude tahun yang terbaca OCR dari tanggal (e.g. 2027, 2026)
    if (value >= 1900 && value <= 2099) return false;
    if (value < _minPrice || value > _maxPrice) {
      return false;
    }
    return true;
  }
}

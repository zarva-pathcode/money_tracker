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
    'GOPAY': ['GOPAY', 'G0PAY', 'GOP4Y'],
    'OVO': ['OVO', '0V0', 'OVO'],
    'SHOPEEPAY': ['SHOPEEPAY', 'SHOPEEP4Y', 'SPAY'],
    'DANA': ['DANA', 'DAN4', 'DANA'],
    'PEMBAYARAN SEBENARNYA': ['PEMBAYARAN SEBENARNYA', 'PEMBAYARAN', 'PEMB4YARAN SEBENARNYA'],
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
    // Level 1: Total belanja bersih (paling akurat, tidak sekadar uang tunai)
    // Level 2: Pembayaran digital / total umum
    // Level 3: Tunai fisik (CASH/TUNAI) — hanya digunakan sebagai fallback terakhir
    final priorities = [
      ['GRAND TOTAL', 'TOTAL BAYAR', 'PEMBAYARAN SEBENARNYA', 'TOTAL TAGIHAN',
       'TOTAL BELANJA', 'NET TOTAL', 'NETTO', 'TOTAL AKHIR'],
      ['TOTAL HARGA', 'TOTAL', 'JUMLAH', 'AMOUNT', 'QRIS', 'DEBIT', 'KREDIT',
       'GOPAY', 'OVO', 'SHOPEEPAY', 'DANA', 'VISA', 'CHARGE', 'SUBTOTAL'],
      ['CASH', 'TUNAI', 'BAYAR'],
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
            // Special case: jika keyword adalah CASH/TUNAI/BAYAR, jangan langsung
            // kembalikan harga pertama. Scan 5 baris ke bawah dan cari total belanja
            // dengan logika Cash - Change = Total.
            if (group.first == 'CASH') {
              final smartTotal = _resolveCashChange(normalized, i, j);
              if (smartTotal != null) {
                debugPrint("ReceiptParser: smart CASH resolved -> $smartTotal");
                return smartTotal;
              }
            }
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
    
    // Coba temukan hubungan Cash - Kembali = Total
    if (allPrices.isNotEmpty) {
      allPrices.sort((a, b) => b.compareTo(a));
      // Hanya lihat 5 angka terbesar yang potensial menjadi nominal pembayaran
      final topPrices = allPrices.take(10).toList();
      
      for (int i = 0; i < topPrices.length; i++) {
        for (int j = i + 1; j < topPrices.length; j++) {
           double maxVal = topPrices[i]; // Diduga Uang Tunai (e.g. 150.000)
           double midVal = topPrices[j]; // Diduga Total Belanja (e.g. 120.800)
           
           // Jika selisihnya cocok dengan angka kembalian yang ada di struk
           // Toleransi pembulatan kantong plastik / donasi (±1000)
           double diff = maxVal - midVal;
           bool hasChangeMatch = topPrices.any((val) => (val - diff).abs() <= 1000);
           
           if (hasChangeMatch && midVal > _minPrice) {
               debugPrint("ReceiptParser: math relation found! Cash: $maxVal, Total: $midVal");
               return midVal;
           }
        }
      }

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

  /// Cerdas membedakan Uang Tunai vs Total Belanja
  static double? _resolveCashChange(List<String> normalized, int startLine, int currentJ) {
    // Kumpulkan seluruh angka di 5-7 baris ke bawah setelah keyword CASH ditemukan
    final prices = <double>[];
    for (int k = 0; k <= 7 && startLine + k < normalized.length; k++) {
       prices.addAll(_extractPrices(normalized[startLine + k]));
    }
    
    if (prices.length >= 2) {
      prices.sort((a, b) => b.compareTo(a));
      // Cari hubungan Tunai - Kembali = Total Belanja
      for (int m = 0; m < prices.length; m++) {
        for (int n = m + 1; n < prices.length; n++) {
           double cash = prices[m];
           double total = prices[n];
           double diff = cash - total;
           bool hasChangeMatch = prices.any((val) => (val - diff).abs() <= 1000);
           
           // Jika math relation terpenuhi dan total masuk akal (mencegah Rp0)
           if (hasChangeMatch && total > _minPrice) {
               return total;
           }
        }
      }
    }
    return null; // Gagal memvalidasi logik kasir
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
    
    // Jangan proses baris yang kelihatannya berisi kuantitas barang
    if (RegExp(r'\d+\s*[xX]\s*\d+').hasMatch(line)) return result;
    if (line.toUpperCase().contains('PCS')) return result;
    if (line.contains('@')) return result;

    // Pattern: ribuan.detik → ribuan,detik → integer (prioritas tinggi ke rendah)
    // Menggunakan word character boundaries (\b) untuk mencegah pemotongan
    final pricePattern = RegExp(
      r'\b\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?\b|\b\d+\b',
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

    // Debug: log semua harga yang ditemukan per baris
    if (result.isNotEmpty) {
      debugPrint("ReceiptParser _extractPrices('$line') -> $result");
    }

    return result;
  }

  static double? _parsePrice(String raw) {
    String s = raw;

    // Buang separator di ujung
    s = s.replaceAll(RegExp(r'^[.,]+|[.,]+$'), '');

    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    
    int lastSepIndex = lastDot > lastComma ? lastDot : lastComma;

    if (lastSepIndex != -1) {
      // Hitung ada berapa karakter setelah pemisah terakhir
      int charsAfterSep = s.length - lastSepIndex - 1;

      if (charsAfterSep == 1 || charsAfterSep == 2) {
        // Ini adalah desimal (mis. ,50 atau .00)
        // Hapus semua pemisah ribuan di depan, jadikan pemisah akhir sebagai '.'
        String intPart = s.substring(0, lastSepIndex).replaceAll(RegExp(r'[.,]'), '');
        String decPart = s.substring(lastSepIndex + 1);
        s = '$intPart.$decPart';
      } else {
        // charsAfterSep == 3 (mis. .000 atau ,500)
        // Berarti ini pemisah ribuan. Buang semua titik/koma.
        s = s.replaceAll(RegExp(r'[.,]'), '');
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

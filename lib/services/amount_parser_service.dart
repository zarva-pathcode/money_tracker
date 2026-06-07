import '../services/dictionary_service.dart';

class AmountToken {
  final int value;
  final TokenType type;

  AmountToken(this.value, this.type);
}

enum TokenType { unit, base, multiplier }

/// Span moneter dalam teks: posisi, full match, raw text, suffix.
class MonetarySpan {
  final int start;
  final String fullMatch;
  final String rawText;
  final String? monetarySuffix;

  MonetarySpan({
    required this.start,
    required this.fullMatch,
    required this.rawText,
    this.monetarySuffix,
  });

  int get end => start + fullMatch.length;
}

class AmountParserService {
  AmountParserService._();

  static const Map<String, int> _numberWords = {
    'satu': 1, 'dua': 2, 'tiga': 3, 'empat': 4,
    'lima': 5, 'enam': 6, 'tujuh': 7, 'delapan': 8, 'sembilan': 9,
  };

  static final DictionaryService _dict = DictionaryService.instance;

  // ---- Optimasi: compiled regex static ----
  static final _digitPattern = RegExp(r'(\d[\d,.]*)\s*(rb|k|ribu|rebu|juta|jt)?');
  static final _slangPattern = RegExp(
    r'\b(seceng|noceng|goceng|ceban|noban|goban|cepek|gopek)\b');
  static final _setengahPattern = RegExp(
    r'\bsetengah\s+(juta|jt|ribu|rb|k)\b');
  static final _numberCleanup = RegExp(r'^\d{1,3}(,\d{3})+$');
  static final _dotThousand = RegExp(r'\.(\d{3})(?=\d|$)');

  // ---- backward compat (leftmost) ----
  static int? extractAmount(String text) {
    var input = text.toLowerCase();
    input = _preprocessSlang(input);
    input = _preprocessSetengah(input);

    final digitMatch = _digitPattern.firstMatch(input);
    if (digitMatch != null) {
      return _parseDigitMatch(digitMatch);
    }
    return _parseNumberWords(input);
  }

  // ---- backward compat (rightmost, per clause) ----
  static ({int? amount, String remaining}) extractRightmost(String clause) {
    if (clause.trim().isEmpty) return (amount: null, remaining: clause);

    final text = clause.toLowerCase();
    final matches = findAllMonetarySpans(text);
    if (matches.isEmpty) return (amount: null, remaining: clause);

    for (final span in matches.reversed) {
      final amt = tryParseRaw(span.rawText, span.monetarySuffix);
      if (amt == null || amt <= 0) continue;
      if (!isMonetary(span, text, amt)) continue;

      final remaining = _removeLastMatch(clause, span.fullMatch);
      return (amount: amt, remaining: remaining.trim());
    }

    return (amount: null, remaining: clause);
  }

  // ---- Public methods untuk single-pass parse ----

  /// Cari semua span moneter dalam teks (satu pass).
  static List<MonetarySpan> findAllMonetarySpans(String text) {
    final spans = <MonetarySpan>[];

    for (final m in _digitPattern.allMatches(text)) {
      spans.add(MonetarySpan(
        start: m.start,
        fullMatch: m.group(0)!,
        rawText: m.group(1)!,
        monetarySuffix: m.group(2),
      ));
    }

    for (final m in _slangPattern.allMatches(text)) {
      final slang = m.group(1)!;
      if (_slangValue(slang) > 0) {
        spans.add(MonetarySpan(
          start: m.start,
          fullMatch: m.group(0)!,
          rawText: slang,
          monetarySuffix: null,
        ));
      }
    }

    for (final m in _setengahPattern.allMatches(text)) {
      spans.add(MonetarySpan(
        start: m.start,
        fullMatch: m.group(0)!,
        rawText: m.group(0)!,
        monetarySuffix: m.group(1),
      ));
    }

    spans.sort((a, b) => a.start.compareTo(b.start));
    return spans;
  }

  /// Parse raw text sebagai angka.
  static int? tryParseRaw(String raw, String? suffix) {
    // Slang word
    final slangVal = _slangValue(raw);
    if (slangVal > 0) return slangVal;

    // "setengah sesuatu"
    if (raw.startsWith('setengah ')) {
      final multKey = raw.split(' ').last;
      final multVal = (multKey == 'juta' || multKey == 'jt') ? 1000000 : 1000;
      return multVal ~/ 2;
    }
    if (raw == 'setengah') return 500;

    final numStr = _normalizeNumber(raw);
    final parsedNum = double.tryParse(numStr);
    if (parsedNum == null || parsedNum <= 0) return null;
    return _resolveAmount(parsedNum, suffix);
  }

  /// Validasi apakah span adalah nominal uang.
  static bool isMonetary(MonetarySpan span, String fullText, int amount) {
    if (span.monetarySuffix != null) return true;
    if (_slangValue(span.rawText) > 0) return true;

    final endIdx = span.start + span.fullMatch.length;
    if (endIdx < fullText.length) {
      final after = fullText.substring(endIdx).trimLeft();
      final nextWord = after.split(RegExp(r'\s+')).firstOrNull ?? '';
      if (_dict.isUnitWord(nextWord)) return false;
    }

    if (amount >= 1000) return true;
    return false;
  }

  // ---- Private helpers ----

  static int _slangValue(String slang) {
    switch (slang.toLowerCase()) {
      case 'seceng': return 1000;
      case 'noceng': return 2000;
      case 'goceng': return 5000;
      case 'ceban': return 10000;
      case 'noban': return 20000;
      case 'goban': return 50000;
      case 'cepek': return 100;
      case 'gopek': return 500;
      default: return 0;
    }
  }

  static String _removeLastMatch(String text, String matchText) {
    final idx = text.toLowerCase().lastIndexOf(matchText.toLowerCase());
    if (idx < 0) return text;
    return text.substring(0, idx) + text.substring(idx + matchText.length);
  }

  static int? _parseDigitMatch(RegExpMatch m) {
    final raw = m.group(1)!;
    final numStr = _normalizeNumber(raw);
    final num = double.tryParse(numStr);
    if (num != null && num > 0) {
      return _resolveAmount(num, m.group(2));
    }
    return null;
  }

  static int _resolveAmount(double num, String? suffix) {
    if (suffix != null) {
      if (suffix == 'rb' || suffix == 'k' || suffix == 'ribu' || suffix == 'rebu') {
        return (num * 1000).round();
      }
      if (suffix == 'juta' || suffix == 'jt') {
        return (num * 1000000).round();
      }
    }
    return num.round();
  }

  static String _normalizeNumber(String raw) {
    if (_numberCleanup.hasMatch(raw)) {
      raw = raw.replaceAll(',', '');
    }
    return raw.replaceAllMapped(_dotThousand, (m) => m.group(1)!)
        .replaceAll(',', '.');
  }

  static String _preprocessSlang(String input) {
    // Only used by backward compat extractAmount
    final slangMap = {
      'seceng': '1000', 'noceng': '2000', 'goceng': '5000',
      'ceban': '10000', 'noban': '20000', 'goban': '50000',
      'cepek': '100', 'gopek': '500',
    };
    slangMap.forEach((slang, replacement) {
      input = input.replaceAll(RegExp(r'\b' + slang + r'\b'), replacement);
    });
    return input;
  }

  static String _preprocessSetengah(String input) {
    return input.replaceAllMapped(
      RegExp(r'(?:(\w+)\s+)?setengah\s+(juta|jt|ribu|rb|k)\b'),
      (m) {
        final intPart = m.group(1);
        final multKey = m.group(2)!;
        final multVal = (multKey == 'juta' || multKey == 'jt') ? 1000000 : 1000;
        if (intPart != null && _numberWords.containsKey(intPart)) {
          final intVal = _numberWords[intPart]!;
          return '${intVal * multVal + multVal ~/ 2}';
        }
        return '${multVal ~/ 2}';
      },
    );
  }

  static int? _parseNumberWords(String text) {
    final tokens = _tokenizeNumberWords(text);
    if (tokens.isEmpty) return null;
    int total = 0, current = 0;
    for (final t in tokens) {
      if (t.value >= 1000) {
        if (current == 0) current = 1;
        current *= t.value;
        total += current;
        current = 0;
      } else if (t.value >= 100) {
        if (current == 0) current = 1;
        total += current * t.value;
        current = 0;
      } else if (t.value == 10 && current > 0 && current < 10) {
        current *= t.value;
      } else {
        current += t.value;
      }
    }
    total += current;
    return total > 0 ? total : null;
  }

  static List<AmountToken> _tokenizeNumberWords(String text) {
    final result = <AmountToken>[];
    final words = text.split(RegExp(r'\s+'));
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w == 'se' && i + 1 < words.length) {
        final n = words[i + 1];
        if (n == 'puluh' || n == 'ratus' || n == 'ribu' || n == 'rebu' || n == 'juta') {
          result.add(AmountToken(
            n == 'puluh' ? 10 : n == 'ratus' ? 100 : (n == 'ribu' || n == 'rebu') ? 1000 : 1000000,
            TokenType.multiplier,
          ));
          i++; continue;
        }
      }
      if (w == 'seratus') { result.add(AmountToken(100, TokenType.multiplier)); continue; }
      if (w == 'seribu') { result.add(AmountToken(1000, TokenType.multiplier)); continue; }
      if (w == 'sejuta' || w == 'sejutaan') { result.add(AmountToken(1000000, TokenType.multiplier)); continue; }
      if (w == 'sepuluh') { result.add(AmountToken(10, TokenType.multiplier)); continue; }
      if (w == 'sebelas') { result.add(AmountToken(11, TokenType.unit)); continue; }
      if (_numberWords.containsKey(w)) {
        final val = _numberWords[w]!;
        if (i + 1 < words.length) {
          final n = words[i + 1];
          if (n == 'belas') { result.add(AmountToken(val + 10, TokenType.unit)); i++; continue; }
          if (n == 'puluh') { result.add(AmountToken(val, TokenType.base)); result.add(AmountToken(10, TokenType.multiplier)); i++; continue; }
          if (n == 'ratus') { result.add(AmountToken(val, TokenType.base)); result.add(AmountToken(100, TokenType.multiplier)); i++; continue; }
          if (n == 'ribu' || n == 'ribuan' || n == 'rebu') { result.add(AmountToken(val, TokenType.base)); result.add(AmountToken(1000, TokenType.multiplier)); i++; continue; }
          if (n == 'juta' || n == 'jutaan') { result.add(AmountToken(val, TokenType.base)); result.add(AmountToken(1000000, TokenType.multiplier)); i++; continue; }
        }
        result.add(AmountToken(val, TokenType.unit));
        continue;
      }
    }
    return result;
  }
}

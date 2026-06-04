class AmountToken {
  final int value;
  final TokenType type;

  AmountToken(this.value, this.type);
}

enum TokenType { unit, base, multiplier }

class AmountParserService {
  static const Map<String, int> _numberWords = {
    'satu': 1, 'dua': 2, 'tiga': 3, 'empat': 4,
    'lima': 5, 'enam': 6, 'tujuh': 7, 'delapan': 8, 'sembilan': 9,
  };

  static int? extractAmount(String text) {
    final input = text.toLowerCase();

    final digitMatch = RegExp(r'(\d[\d.]*)\s*(rb|k|ribu|juta|jt)?')
        .firstMatch(input);
    if (digitMatch != null) {
      final numStr = digitMatch.group(1)!.replaceAll('.', '');
      final num = int.tryParse(numStr);
      if (num != null && num > 0) {
        final suffix = digitMatch.group(2);
        if (suffix != null) {
          if (suffix == 'rb' || suffix == 'k' || suffix == 'ribu') {
            return num * 1000;
          }
          if (suffix == 'juta' || suffix == 'jt') {
            return num * 1000000;
          }
        }
        return num;
      }
    }

    return _parseNumberWords(input);
  }

  static int? _parseNumberWords(String text) {
    final tokens = _tokenizeNumberWords(text);
    if (tokens.isEmpty) return null;

    int total = 0;
    int current = 0;

    for (final token in tokens) {
      if (token.value >= 1000) {
        if (current == 0) current = 1;
        current *= token.value;
        total += current;
        current = 0;
      } else if (token.value >= 100) {
        if (current == 0) current = 1;
        total += current * token.value;
        current = 0;
      } else if (token.value == 10 && current > 0 && current < 10) {
        current *= token.value;
      } else {
        current += token.value;
      }
    }

    total += current;
    return total > 0 ? total : null;
  }

  static List<AmountToken> _tokenizeNumberWords(String text) {
    final result = <AmountToken>[];
    final words = text.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      if (word == 'se' && i + 1 < words.length) {
        final next = words[i + 1];
        if (next == 'puluh' || next == 'ratus' ||
            next == 'ribu' || next == 'juta') {
          final mult = next == 'puluh' ? 10 : next == 'ratus' ? 100 :
                       next == 'ribu' ? 1000 : 1000000;
          result.add(AmountToken(mult, TokenType.multiplier));
          i++;
          continue;
        }
      }

      if (word == 'seratus') {
        result.add(AmountToken(100, TokenType.multiplier)); continue;
      }
      if (word == 'seribu') {
        result.add(AmountToken(1000, TokenType.multiplier)); continue;
      }
      if (word == 'sejuta' || word == 'sejutaan') {
        result.add(AmountToken(1000000, TokenType.multiplier)); continue;
      }
      if (word == 'sepuluh') {
        result.add(AmountToken(10, TokenType.multiplier)); continue;
      }
      if (word == 'sebelas') {
        result.add(AmountToken(11, TokenType.unit)); continue;
      }

      if (_numberWords.containsKey(word)) {
        final val = _numberWords[word]!;

        if (i + 1 < words.length) {
          final next = words[i + 1];
          if (next == 'belas') {
            result.add(AmountToken(val + 10, TokenType.unit));
            i++; continue;
          }
          if (next == 'puluh') {
            result.add(AmountToken(val, TokenType.base));
            result.add(AmountToken(10, TokenType.multiplier));
            i++; continue;
          }
          if (next == 'ratus') {
            result.add(AmountToken(val, TokenType.base));
            result.add(AmountToken(100, TokenType.multiplier));
            i++; continue;
          }
          if (next == 'ribu' || next == 'ribuan') {
            result.add(AmountToken(val, TokenType.base));
            result.add(AmountToken(1000, TokenType.multiplier));
            i++; continue;
          }
          if (next == 'juta' || next == 'jutaan') {
            result.add(AmountToken(val, TokenType.base));
            result.add(AmountToken(1000000, TokenType.multiplier));
            i++; continue;
          }
        }

        result.add(AmountToken(val, TokenType.unit));
        continue;
      }
    }

    return result;
  }
}

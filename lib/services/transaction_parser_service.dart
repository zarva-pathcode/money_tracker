import '../utils/constants.dart' as constants;
import '../utils/parser_constants.dart';
import 'amount_parser_service.dart';
import 'text_parser_service.dart';

class ParsedTransaction {
  final String type;
  final String description;
  final int amount;
  final String category;
  final String? intent;

  ParsedTransaction({
    required this.type,
    required this.description,
    required this.amount,
    this.category = 'Lainnya',
    this.intent,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'description': description,
    'amount': amount,
    'category': category,
  };

  @override
  String toString() =>
      'ParsedTransaction(type: $type, description: $description, '
      'amount: $amount, category: $category)';
}

class TransactionParserService {
  static bool _isIncomeText(String text) {
    final lower = text.toLowerCase();
    for (final pattern in ParserConstants.incomePatterns) {
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }

  static List<ParsedTransaction> parse(String input) {
    if (input.trim().isEmpty) return [];

    print('[STT Input] $input');

    final clauses = TextParserService.splitIntoClauses(input);
    print('[STT Clauses] $clauses');

    final results = <ParsedTransaction>[];

    for (final clause in clauses) {
      final trimmed = clause.trim();
      if (trimmed.isEmpty) continue;

      final parsed = _parseSingle(trimmed);
      if (parsed != null) {
        results.add(parsed);
      }
    }

    final merged = _mergeByIntent(results);
    print('[STT Result] ${merged.map((r) => "${r.description}=Rp${r.amount}")}');
    return merged;
  }

  static List<ParsedTransaction> _mergeByIntent(List<ParsedTransaction> list) {
    if (list.length <= 1) return list;

    final merged = <ParsedTransaction>[];
    ParsedTransaction? current;

    for (final item in list) {
      if (current == null) {
        current = item;
      } else {
        final sameCategory = current.type == item.type &&
            current.amount > 0 && item.amount > 0 &&
            current.category == item.category;

        if (sameCategory) {
          current = ParsedTransaction(
            type: current.type,
            description: '${current.description}, ${item.description}',
            amount: current.amount + item.amount,
            category: current.category == 'Lainnya' ? item.category : current.category,
            intent: current.intent ?? item.intent,
          );
        } else {
          merged.add(current);
          current = item;
        }
      }
    }

    if (current != null) merged.add(current);
    return merged;
  }

  static ParsedTransaction? _parseSingle(String text) {
    if (text.isEmpty) return null;

    final clean = text.toLowerCase().trim();
    final intent = _matchIntent(clean);
    final amount = AmountParserService.extractAmount(clean);
    final description = _buildDescription(clean, intent, amount);
    final type = intent != null && ParserConstants.incomeIntents.contains(intent)
        ? 'income'
        : (intent == null && _isIncomeText(clean))
            ? 'income'
            : 'expense';
    final category = _inferCategory(description, type, intent: intent);

    return ParsedTransaction(
      type: type,
      description: description,
      amount: amount ?? 0,
      category: category,
      intent: intent,
    );
  }

  static String? _matchIntent(String text) {
    for (final kw in [...ParserConstants.incomeIntents, ...ParserConstants.expenseIntents]) {
      if (text.startsWith('$kw ')) return _normalizeIntent(kw);
    }
    for (final kw in [...ParserConstants.incomeIntents, ...ParserConstants.expenseIntents]) {
      if (text.contains(' $kw ') || text.endsWith(' $kw')) {
        return _normalizeIntent(kw);
      }
    }
    if (text.startsWith('gajian') || text.startsWith('bonus')) {
      return text.startsWith('gajian') ? 'gajian' : 'bonus';
    }
    return null;
  }

  static String _normalizeIntent(String raw) {
    if (raw == 'transfer') return 'tf masuk';
    if (raw == 'belikan' || raw == 'bayarin') return raw.substring(0, 4);
    return raw;
  }

  static String _inferCategory(String description, String type, {String? intent}) {
    if (type == 'income' && intent != null) {
      if (intent == 'tf masuk' || intent == 'gajian') return 'Gaji';
      if (intent == 'bonus' || intent == 'thr') return 'Bonus';
    }

    if (description.isEmpty) return 'Lainnya';

    final desc = description.toLowerCase();

    for (final keyword in ParserConstants.sortedKeywords) {
      if (desc.contains(keyword)) {
        final matchedCategory = ParserConstants.keywordCategory[keyword]!;
        if (type == 'expense' && constants.Constants.expenseCategories.contains(matchedCategory)) {
          return matchedCategory;
        }
        if (type == 'income' && constants.Constants.incomeCategories.contains(matchedCategory)) {
          return matchedCategory;
        }
      }
    }

    return 'Lainnya';
  }

  static String _buildDescription(String cleanText, String? intent, int? amount) {
    var rest = cleanText;

    if (intent != null) {
      rest = rest.replaceFirst(intent, '').trim();
    }

    final words = rest.split(RegExp(r'\s+'));
    final removeIdx = <int>{};

    for (int i = 0; i < words.length; i++) {
      if (_isNumberWord(words[i]) || RegExp(r'^\d+$').hasMatch(words[i])) {
        int j = i;
        while (j < words.length &&
            (_isNumberWord(words[j]) || RegExp(r'^\d+$').hasMatch(words[j]))) {
          j++;
        }
        for (int k = i; k < j; k++) removeIdx.add(k);
        i = j - 1;
      }
    }

    rest = words.asMap()
        .entries
        .where((e) => !removeIdx.contains(e.key))
        .map((e) => e.value)
        .join(' ')
        .trim();

    final digitsFound = RegExp(r'\d[\d.]*\s*(rb|k|ribu|juta|jt)?')
        .allMatches(rest)
        .toList();
    for (int i = digitsFound.length - 1; i >= 0; i--) {
      rest = rest.replaceRange(digitsFound[i].start, digitsFound[i].end, '');
    }
    rest = rest.trim();

    rest = rest.replaceAll(RegExp(r'^(dan\s|,\s*)+'), '');
    rest = rest.replaceAll(RegExp(r'(dan\s|,\s*)+$'), '');
    rest = rest.replaceAll(RegExp(r'(?<![a-z])rp(?![a-z])', caseSensitive: false), '');
    rest = rest.replaceAll(RegExp(r'[.,;]+$'), '');
    rest = rest.replaceAll(RegExp(r'^[.,;]+'), '');
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    return _capitalizeFirst(rest);
  }

  static bool _isNumberWord(String word) {
    if (['satu', 'dua', 'tiga', 'empat', 'lima', 'enam',
         'tujuh', 'delapan', 'sembilan'].contains(word)) {
      return true;
    }
    if (['puluh', 'belas', 'ratus', 'ribu', 'ribuan',
         'juta', 'jutaan', 'se', 'seratus', 'seribu',
         'sejuta', 'sejutaan', 'sepuluh', 'sebelas'].contains(word)) {
      return true;
    }
    return RegExp(r'^\d+$').hasMatch(word);
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

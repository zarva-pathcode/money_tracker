import '../services/dictionary_service.dart';
import '../services/amount_parser_service.dart';
import '../services/text_parser_service.dart';
import '../utils/constants.dart' as constants;

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
  TransactionParserService._();

  static final DictionaryService _dict = DictionaryService.instance;

  // ---- Static compiled regex ----
  static final _whitespace = RegExp(r'\s+');
  static final _sepStart = RegExp(r'^(dan\s|,\s*)+');
  static final _sepEnd = RegExp(r'(dan\s|,\s*)+$');
  static final _trailingPunct = RegExp(r'[.,;]+$');
  static final _rpPattern = RegExp(r'\brp\b', caseSensitive: false);

  /// Parse teks STT menjadi list transaksi.
  ///
  /// Flow single-pass:
  /// 1. findAllMonetarySpans — scan sekali untuk semua anchor
  /// 2. Setiap span → 1 klausa (dibatasi oleh posisi span)
  /// 3. Langsung ekstrak amount + intent + deskripsi
  /// 4. Merge same-category
  static List<ParsedTransaction> parse(String input) {
    if (input.trim().isEmpty) return [];

    print('[STT Input] $input');

    final text = input.toLowerCase().trim();
    final spans = AmountParserService.findAllMonetarySpans(text);
    if (spans.isEmpty) return [];

    final results = <ParsedTransaction>[];
    int prevEnd = 0;

    for (final span in spans) {
      if (span.start < prevEnd) continue;

      // Amount
      final amount = AmountParserService.tryParseRaw(
          span.rawText, span.monetarySuffix);
      if (amount == null || amount <= 0) continue;
      if (!AmountParserService.isMonetary(span, text, amount)) continue;

      // Klausa = text dari prevEnd sampai akhir span
      final clauseText = text.substring(prevEnd, span.end).trim();
      if (clauseText.isEmpty) continue;

      // Sisa teks = clause tanpa fullMatch amount
      final remaining = _buildRawDescription(text, prevEnd, span);

      // Intent
      final intent = _dict.matchIntent(clauseText);

      // Deskripsi bersih
      final description = _buildDescription(remaining, intent);

      // Type
      final type = _determineType(clauseText, intent);

      // Kategori
      final category = _inferCategory(description, type, intent: intent);

      results.add(ParsedTransaction(
        type: type,
        description: description,
        amount: amount,
        category: category,
        intent: intent,
      ));

      prevEnd = span.end;
    }

    final merged = _mergeSameCategory(results);
    print('[STT Result] ${merged.map((r) => "${r.description}=Rp${r.amount} (${r.category})")}');

    return merged;
  }

  /// Ambil teks mentah dari clause tanpa fullMatch amount.
  static String _buildRawDescription(String text, int prevEnd, MonetarySpan span) {
    return text.substring(prevEnd, span.start).trim();
  }

  /// Bangun deskripsi bersih: hapus intent + stopwords + cleanup.
  static String _buildDescription(String raw, String? intent) {
    var desc = raw;

    // Hapus intent
    if (intent != null) {
      final idx = desc.toLowerCase().indexOf(intent);
      if (idx >= 0) {
        desc = desc.substring(0, idx) + desc.substring(idx + intent.length);
      }
    }

    // Hapus stopwords
    desc = TextParserService.removeStopwords(desc);

    // Cleanup gabungan (3 pass instead of 6)
    desc = desc.replaceAll(_whitespace, ' ').trim();
    desc = desc.replaceAll(_sepStart, '');
    desc = desc.replaceAll(_sepEnd, '');
    desc = desc.replaceAll(_trailingPunct, '');
    desc = desc.replaceAll(_rpPattern, '');
    desc = desc.replaceAll(_whitespace, ' ').trim();

    return _capitalizeFirst(desc);
  }

  /// Tentukan type transaksi (income/expense).
  static String _determineType(String text, String? intent) {
    if (intent != null && _dict.isIncomeIntent(intent)) return 'income';
    if (intent == null && _isIncomeText(text)) return 'income';
    if (_dict.containsIncomeKeyword(text)) return 'income';
    return 'expense';
  }

  static bool _isIncomeText(String text) {
    return RegExp(r'^(?:gaji|bonus|honor|upah|cair|dikasih|diberi|thr)\b')
        .hasMatch(text.toLowerCase());
  }

  /// Infer kategori berdasarkan deskripsi.
  static String _inferCategory(String description, String type, {String? intent}) {
    if (type == 'income' && intent != null) {
      if (intent == 'gajian' || intent == 'tf masuk') return 'Gaji';
      if (intent == 'bonus' || intent == 'thr') return 'Bonus';
    }

    if (description.isEmpty) return 'Lainnya';

    final cat = _dict.inferCategory(description, type);
    if (type == 'expense' &&
        constants.Constants.expenseCategories.contains(cat)) {
      return cat;
    }
    if (type == 'income' &&
        constants.Constants.incomeCategories.contains(cat)) {
      return cat;
    }

    return 'Lainnya';
  }

  /// Merge klausa dengan kategori dan type yang sama.
  static List<ParsedTransaction> _mergeSameCategory(List<ParsedTransaction> list) {
    if (list.length <= 1) return list;

    final merged = <ParsedTransaction>[];
    ParsedTransaction? current;

    for (final item in list) {
      if (current == null) {
        current = item;
      } else if (current.type == item.type &&
          current.category == item.category &&
          current.amount > 0 && item.amount > 0) {
        current = ParsedTransaction(
          type: current.type,
          description: '${current.description}, ${item.description}',
          amount: current.amount + item.amount,
          category: current.category,
          intent: current.intent ?? item.intent,
        );
      } else {
        merged.add(current);
        current = item;
      }
    }

    if (current != null) merged.add(current);
    return merged;
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

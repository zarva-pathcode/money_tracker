import 'package:petitparser/petitparser.dart';
import '../utils/parser_constants.dart';

class TextParserService {
  static final Parser<List<String>> _clauseSplitter = _buildClauseSplitter();

  static final Set<String> _intentKeywords = {
    ...ParserConstants.expenseIntents,
    ...ParserConstants.incomeIntents,
  };

  static Parser<List<String>> _buildClauseSplitter() {
    final separator = (
      string(' dan ') |
      string(', ') |
      string(' , ') |
      string(' terus ') |
      string(' abis itu ') |
      string(' trus ') |
      string('; ') |
      string(' ; ')
    );

    final clause = (separator.not() & any())
        .map((pair) => pair[1] as String)
        .plus()
        .map((chars) => chars.join())
        .trim();

    return clause.plusSeparated(separator).map((separated) {
      return separated.elements
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    });
  }

  static List<String> splitIntoClauses(String text) {
    String input = text.trim().toLowerCase();
    input = _normalizeSeparators(input);

    List<String> clauses;
    try {
      clauses = _clauseSplitter.parse(input).value;
    } catch (_) {
      clauses = [];
    }

    if (clauses.length <= 1) {
      clauses = _splitByIntent(input);
    }

    return _expandClauses(clauses);
  }

  static String _normalizeSeparators(String text) {
    return text.replaceAllMapped(
      RegExp(r'\. (?!\d)'),
      (_) => ', ',
    );
  }

  static List<String> _splitByIntent(String text) {
    final splitPositions = <int>{};

    for (final intent in _intentKeywords) {
      final pattern = ' $intent ';
      int start = 0;
      while (true) {
        final pos = text.indexOf(pattern, start);
        if (pos == -1) break;
        splitPositions.add(pos + 1);
        start = pos + 1;
      }
      if (text.endsWith(' $intent')) {
        splitPositions.add(text.length - intent.length);
      }
    }

    if (splitPositions.isEmpty) return [text];

    final sorted = splitPositions.toList()..sort();
    final result = <String>[];
    int lastPos = 0;

    for (final pos in sorted) {
      if (pos <= lastPos) continue;
      final clause = text.substring(lastPos, pos).trim();
      if (clause.isNotEmpty) result.add(clause);
      lastPos = pos;
    }
    final lastClause = text.substring(lastPos).trim();
    if (lastClause.isNotEmpty) result.add(lastClause);

    return result;
  }

  static List<String> _expandClauses(List<String> clauses) {
    final result = <String>[];
    for (final clause in clauses) {
      final expanded = _extractNumberPairs(clause);
      result.addAll(expanded);
    }
    return result.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  }

  static List<String> _extractNumberPairs(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\brp\s*(\d[\d,.]*\s*(?:rb|k|ribu|ribuan|juta|jutaan|jt|belas|puluh|puluhan|ratus|ratusan)?)', caseSensitive: false),
      (m) => m.group(1)!,
    );
    const suffix =
        r'(?:rb|k|ribu|ribuan|juta|jutaan|jt|'
        r'belas|puluh|puluhan|ratus|ratusan)?';
    final regex = RegExp(r'(.+?)\s+(\d[\d,.]*\s*' + suffix + r')');
    final matches = regex.allMatches(text);
    if (matches.length <= 1) return [text];

    int lastEnd = 0;
    final result = <String>[];
    for (final m in matches) {
      final clause = text.substring(lastEnd, m.end).trim();
      if (clause.isNotEmpty) result.add(clause);
      lastEnd = m.end;
    }
    final tail = text.substring(lastEnd).trim();
    if (tail.isNotEmpty) result.add(tail);

    return result;
  }
}

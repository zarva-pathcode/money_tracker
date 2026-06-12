import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'hive_service.dart';

class DictionaryService {
  DictionaryService._();
  static final DictionaryService _instance = DictionaryService._();
  static DictionaryService get instance => _instance;

  HiveService? _hiveService;
  Map<String, String> _localCorrections = {};

  void setHiveService(HiveService service) {
    _hiveService = service;
    _localCorrections = service.getAllWordCorrections();
  }

  bool _loaded = false;
  late Map<String, dynamic> _data;
  late Set<String> _stopwords;
  late Set<String> _separators;
  late Set<String> _monetarySuffixes;
  late Set<String> _unitWords;
  late Map<String, List<String>> _categoryKeywords;
  late Map<String, String> _keywordCategory;
  late List<String> _sortedKeywords;
  late Set<String> _expenseIntents;
  late Set<String> _incomeIntents;
  late Set<String> _incomeCategoryKeywords;

  static const Set<String> _incomeCategoryNames = {'Gaji', 'Bonus', 'Investasi'};

  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/json/dictionary.json');
    _data = jsonDecode(jsonStr) as Map<String, dynamic>;

    _stopwords = (_data['stopwords'] as List).map((e) => e.toString()).toSet();
    _separators = (_data['separators'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    _monetarySuffixes = (_data['monetary_suffixes'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    _unitWords = (_data['unit_words'] as List?)?.map((e) => e.toString()).toSet() ?? {};

    final intents = _data['intents'] as Map<String, dynamic>;
    _expenseIntents = (intents['expense'] as List).map((e) => e.toString()).toSet();
    _incomeIntents = (intents['income'] as List).map((e) => e.toString()).toSet();

    _categoryKeywords = {};
    final cats = _data['category_keywords'] as Map<String, dynamic>;
    for (final entry in cats.entries) {
      _categoryKeywords[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
    }

    _keywordCategory = {};
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        _keywordCategory[kw] = entry.key;
      }
    }

    _sortedKeywords = _keywordCategory.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    _incomeCategoryKeywords = {};
    for (final name in _incomeCategoryNames) {
      final keywords = _categoryKeywords[name];
      if (keywords != null) {
        _incomeCategoryKeywords.addAll(keywords.map((e) => e.toLowerCase()));
      }
    }

    _loaded = true;
  }

  bool isStopword(String word) => _stopwords.contains(word.toLowerCase());
  bool isSeparator(String word) => _separators.contains(word.toLowerCase());
  bool isMonetarySuffix(String word) => _monetarySuffixes.contains(word.toLowerCase());
  bool isUnitWord(String word) => _unitWords.contains(word.toLowerCase());
  bool isExpenseIntent(String word) => _expenseIntents.contains(word.toLowerCase());
  bool isIncomeIntent(String word) => _incomeIntents.contains(word.toLowerCase());

  String? matchIntent(String text) {
    final lower = text.toLowerCase();
    for (final intent in [..._incomeIntents, ..._expenseIntents]) {
      if (lower.startsWith('$intent ') || lower == intent) return intent;
    }
    for (final intent in [..._incomeIntents, ..._expenseIntents]) {
      if (lower.contains(' $intent ')) return intent;
    }
    return null;
  }

  String inferCategory(String description, String type) {
    if (description.isEmpty) return 'Lainnya';
    final desc = description.toLowerCase();

    // 1. Cek koreksi lokal dulu
    for (final entry in _localCorrections.entries) {
      if (desc.contains(entry.key)) return entry.value;
    }

    // 2. Fallback ke dictionary JSON
    for (final keyword in _sortedKeywords) {
      if (desc.contains(keyword)) {
        final cat = _keywordCategory[keyword]!;
        final isExpenseCat = _categoryKeywords.containsKey(cat);
        if (type == 'expense' && isExpenseCat) return cat;
        if (type == 'income' && isExpenseCat) return cat;
      }
    }
    return 'Lainnya';
  }

  Future<void> saveCorrection(String word, String category) async {
    final key = word.toLowerCase().trim();
    _localCorrections[key] = category;
    await _hiveService?.saveWordCorrection(key, category);
  }

  /// Cek apakah teks mengandung keyword dari kategori income (Gaji, Bonus, Investasi).
  bool containsIncomeKeyword(String text) {
    final lower = text.toLowerCase();
    for (final keyword in _incomeCategoryKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }
}

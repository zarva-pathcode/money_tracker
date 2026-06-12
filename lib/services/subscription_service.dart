import '../models/expense.dart';
import '../services/text_normalizer.dart';
import '../services/hive_service.dart';

class SubscriptionInfo {
  final String key;
  String title;
  String category;
  double amount;
  int dayOfMonth;
  bool isAutoDetected;
  bool isActive;

  SubscriptionInfo({
    required this.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    this.isAutoDetected = false,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'key': key,
    'title': title,
    'category': category,
    'amount': amount,
    'dayOfMonth': dayOfMonth,
    'isAutoDetected': isAutoDetected,
    'isActive': isActive,
  };

  factory SubscriptionInfo.fromMap(Map<String, dynamic> m) => SubscriptionInfo(
    key: m['key'] as String,
    title: m['title'] as String,
    category: m['category'] as String,
    amount: (m['amount'] as num).toDouble(),
    dayOfMonth: m['dayOfMonth'] as int,
    isAutoDetected: m['isAutoDetected'] as bool? ?? false,
    isActive: m['isActive'] as bool? ?? true,
  );
}

class SubscriptionService {
  static const double _similarityThreshold = 0.8;
  static const int _minOccurrences = 3;
  static const int _dayTolerance = 2;

  static List<SubscriptionInfo> detectSubscriptions(List<Expense> allExpenses) {
    if (allExpenses.length < 5) return [];

    // Kelompokkan expense berdasarkan title similarity
    final groups = <String, List<Expense>>{};
    final processed = <String>{};

    for (final e in allExpenses) {
      if (e.type != 'expense' || e.category == 'Tabungan') continue;
      if (processed.contains(e.id)) continue;

      final normalized = normalizeTitle(e.title);
      if (normalized.isEmpty) continue;

      final group = <Expense>[e];
      processed.add(e.id);

      for (final other in allExpenses) {
        if (other.type != 'expense' || processed.contains(other.id)) continue;
        final otherNorm = normalizeTitle(other.title);
        if (otherNorm.isEmpty) continue;
        if (similarity(normalized, otherNorm) >= _similarityThreshold) {
          group.add(other);
          processed.add(other.id);
        }
      }

      if (group.length >= _minOccurrences) {
        // Cek apakah terjadi di tanggal yang mirip setiap bulan
        final days = group.map((e) => e.date.day).toList();
        final medianDay = days..sort();
        final mid = medianDay[medianDay.length ~/ 2];
        final withinTolerance = days.every((d) => (d - mid).abs() <= _dayTolerance);
        if (withinTolerance) {
          groups[normalized] = group;
        }
      }
    }

    // Build SubscriptionInfo
    final result = <SubscriptionInfo>[];
    for (final entry in groups.entries) {
      final group = entry.value;
      final totalAmount = group.fold<double>(0, (s, e) => s + e.amount);
      final avgAmount = totalAmount / group.length;
      final mostCommonDay = _mostFrequent(group.map((e) => e.date.day).toList());

      result.add(SubscriptionInfo(
        key: entry.key,
        title: group.first.title,
        category: group.first.category,
        amount: avgAmount,
        dayOfMonth: mostCommonDay,
        isAutoDetected: true,
        isActive: true,
      ));
    }

    return result;
  }

  static List<SubscriptionInfo> loadFromHive(HiveService hiveService) {
    final data = hiveService.getAllSubscriptions();
    return data.values.map((m) => SubscriptionInfo.fromMap(m)).toList();
  }

  static Future<void> saveToHive(HiveService hiveService, List<SubscriptionInfo> subs) async {
    for (final s in subs) {
      await hiveService.saveSubscription(s.key, s.toMap());
    }
  }

  static int _mostFrequent(List<int> items) {
    final freq = <int, int>{};
    int maxCount = 0;
    int mostFreq = items.first;
    for (final n in items) {
      final c = (freq[n] ?? 0) + 1;
      freq[n] = c;
      if (c > maxCount) {
        maxCount = c;
        mostFreq = n;
      }
    }
    return mostFreq;
  }

  /// Cek jika title cocok dengan subscription yang sudah dikenal
  static bool isKnownSubscription(String title, List<SubscriptionInfo> subs) {
    final norm = normalizeTitle(title);
    final normWords = norm.split(' ').toSet();
    return subs.any((s) {
      final subNorm = normalizeTitle(s.title);
      final subWords = subNorm.split(' ').toSet();
      if (normWords.isNotEmpty &&
          (normWords.every((w) => subWords.contains(w)) ||
              subWords.every((w) => normWords.contains(w)))) {
        return true;
      }
      return similarity(norm, subNorm) >= _similarityThreshold;
    });
  }
}

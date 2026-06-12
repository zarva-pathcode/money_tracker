import 'dart:math';

String normalizeTitle(String title) {
  String result = title.toLowerCase().trim();
  result = result.replaceAll(RegExp(r'\s+'), ' ');
  result = result.replaceAllMapped(RegExp(r'([a-z])\1{2,}'), (m) => m.group(1)!);
  result = result.replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '');
  result = result.replaceAll('-', '');
  return result;
}

int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final matrix = List.generate(
    a.length + 1,
    (i) => List.filled(b.length + 1, 0),
  );

  for (var i = 0; i <= a.length; i++) matrix[i][0] = i;
  for (var j = 0; j <= b.length; j++) matrix[0][j] = j;

  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = min(
        min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
        matrix[i - 1][j - 1] + cost,
      );
    }
  }
  return matrix[a.length][b.length];
}

double similarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final distance = levenshteinDistance(a, b).toDouble();
  final maxLen = max(a.length, b.length).toDouble();
  return 1.0 - (distance / maxLen);
}

String? findClosestMatch(String input, List<String> existingTitles,
    {double threshold = 0.7}) {
  if (input.isEmpty) return null;
  final normalizedInput = normalizeTitle(input);
  final inputWords = normalizedInput.split(' ').toSet();

  for (final title in existingTitles) {
    final normalizedExisting = normalizeTitle(title);
    final existingWords = normalizedExisting.split(' ').toSet();
    if (inputWords.isNotEmpty &&
        inputWords.every((w) => existingWords.contains(w))) {
      return title;
    }
    final sim = similarity(normalizedInput, normalizedExisting);
    if (sim >= threshold) return title;
  }
  return null;
}

import '../services/dictionary_service.dart';

class TextParserService {
  TextParserService._();

  static final DictionaryService _dict = DictionaryService.instance;

  /// Hapus stopwords dari teks deskripsi.
  static String removeStopwords(String text) {
    final words = text.split(RegExp(r'\s+'));
    final kept = words.where((w) => !_dict.isStopword(w) && w.isNotEmpty);
    return kept.join(' ').trim();
  }
}

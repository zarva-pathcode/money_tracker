import 'keywords/keyword_belanja.dart';
import 'keywords/keyword_bonus.dart';
import 'keywords/keyword_gaji.dart';
import 'keywords/keyword_hiburan.dart';
import 'keywords/keyword_investasi.dart';
import 'keywords/keyword_kesehatan.dart';
import 'keywords/keyword_makanan.dart';
import 'keywords/keyword_tagihan.dart';
import 'keywords/keyword_transportasi.dart';

class ParserConstants {
  ParserConstants._();

  static const Set<String> expenseIntents = {
    'beli', 'belikan', 'bayar', 'bayarin', 'buat', 'isi',
  };

  static const Set<String> incomeIntents = {
    'tf masuk', 'gajian', 'bonus', 'transfer', 'thr',
  };

  static const Map<String, List<String>> categoryKeywords = {
    'Makanan': makananKeywords,
    'Transportasi': transportasiKeywords,
    'Belanja': belanjaKeywords,
    'Hiburan': hiburanKeywords,
    'Tagihan': tagihanKeywords,
    'Kesehatan': kesehatanKeywords,
    'Gaji': gajiKeywords,
    'Bonus': bonusKeywords,
    'Investasi': investasiKeywords,
  };

  static final Map<String, String> keywordCategory = () {
    final map = <String, String>{};
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        map[keyword] = entry.key;
      }
    }
    return map;
  }();

  static final List<String> sortedKeywords =
      keywordCategory.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  static final List<RegExp> incomePatterns = [
    RegExp(r'^(?:gaji|bonus|honor|upah|cair|dikasih|diberi|thr)\b'),
    RegExp(r'^(?:nerima|terima|dapat)\s+(?:gaji|bonus|uang|dana|duit)\b'),
    RegExp(r'\b(?:tf|transfer)\s+(?:masuk|dikirim|diterima)\b'),
    RegExp(r'\b(?:dana|uang)\s+masuk\b'),
    RegExp(r'\bmasuk\s+(?:rek(?:ening)?|atm|e[\s-]?wallet)\b'),
    RegExp(r'\b(?:e[\s-]?wallet|gopay|ovo|shopeepay)\s+masuk\b'),
    RegExp(r'\bthr\b'),
    RegExp(r'\bkiriman\b'),
    RegExp(r'\btransferan\b'),
    RegExp(r'\bpemasukan\b'),
    RegExp(r'\bpendapatan\b'),
    RegExp(r'\bpenghasilan\b'),
  ];
}

import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatRupiah(num amount) {
    return formatCurrency(amount.toDouble());
  }

  static String formatDayMonth(DateTime date) {
    // Format: Sabtu, 8 April
    return DateFormat('EEEE, d MMM', 'id_ID').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Format input dengan thousand separator
  static String formatNumberInput(String value) {
    if (value.isEmpty) return '';

    // Hapus semua karakter non-digit
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Konversi ke angka
    int number = int.tryParse(digitsOnly) ?? 0;

    // Format dengan thousand separator, ensure 0 is shown
    return NumberFormat('#,##0', 'id_ID').format(number);
  }

  static double parseFormattedNumber(String formatted) {
    String digitsOnly = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digitsOnly) ?? 0;
  }

  static String formatNumber(int number) {
    return NumberFormat('#,##0', 'id_ID').format(number);
  }
}

import 'package:flutter/material.dart';

class Constants {
  // Menggunakan 'static' agar bisa dipanggil langsung tanpa membuat instance kelas
  static Map<String, dynamic> getCategoryStyle(String category) {
    switch (category) {
      case 'Makanan':
        return {
          'icon': Icons.fastfood_rounded, // Icon rounded lebih modern
          'color': const Color(0xFFFF8A65), // Coral Orange
        };
      case 'Transportasi':
        return {
          'icon': Icons.directions_car_rounded,
          'color': const Color(0xFF42A5F5), // Soft Blue
        };
      case 'Belanja':
        return {
          'icon': Icons.shopping_bag_rounded,
          'color': const Color(0xFFAB47BC), // Lilac Purple
        };
      case 'Hiburan':
        return {
          'icon': Icons.movie_rounded,
          'color': const Color(0xFFEC407A), // Raspberry Pink
        };
      case 'Tagihan':
        return {
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFF26A69A), // Teal Green
        };
      case 'Kesehatan':
        return {
          'icon': Icons.medical_services_rounded,
          'color': const Color(0xFFEF5350), // Soft Red
        };
      case 'Lainnya':
        return {
          'icon': Icons.more_horiz_rounded,
          'color': const Color(0xFF78909C), // Blue Grey
        };
      // Kategori Pemasukan
      case 'Gaji':
        return {
          'icon': Icons.attach_money_rounded,
          'color': const Color(0xFF43A047), // Green
        };
      case 'Bonus':
        return {
          'icon': Icons.card_giftcard_rounded,
          'color': const Color(0xFF81C784), // Light Green
        };
      case 'Investasi':
        return {
          'icon': Icons.trending_up_rounded,
          'color': const Color(0xFF00897B), // Teal
        };
      default:
        return {
          'icon': Icons.category_rounded,
          'color': const Color(0xFFBDBDBD), // Grey
        };
    }
  }

  static const List<String> expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Tagihan',
    'Kesehatan',
    'Lainnya',
  ];

  static const List<String> incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
    'Lainnya',
  ];

  static const List<String> categories = [
    'Semua Kategori',
    ...expenseCategories,
    ...incomeCategories,
  ];

  static const List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> amountFilters = [
    'Terbaru',
    'Terlama',
    'Terbesar',
    'Terkecil',
  ];
}

// --- ENUMS (Tetap sama) ---
enum TimeFilter {
  today,
  last7Days,
  thisMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
}

enum SortFilter { newest, oldest, largest, smallest }

enum MonthFilter {
  januari,
  februari,
  maret,
  april,
  mei,
  juni,
  juli,
  agustus,
  september,
  oktober,
  november,
  desember,
  all,
}

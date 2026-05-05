import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Constants {
  // Menggunakan 'static' agar bisa dipanggil langsung tanpa membuat instance kelas
  static Map<String, dynamic> getCategoryStyle(String category) {
    switch (category) {
      case 'Makanan':
        return {
          'icon': FontAwesomeIcons.utensils, 
          'color': const Color(0xFFFF8A65), // Coral Orange
        };
      case 'Transportasi':
        return {
          'icon': FontAwesomeIcons.car,
          'color': const Color(0xFF42A5F5), // Soft Blue
        };
      case 'Belanja':
        return {
          'icon': FontAwesomeIcons.bagShopping,
          'color': const Color(0xFFAB47BC), // Lilac Purple
        };
      case 'Hiburan':
        return {
          'icon': FontAwesomeIcons.film,
          'color': const Color(0xFFEC407A), // Raspberry Pink
        };
      case 'Tagihan':
        return {
          'icon': FontAwesomeIcons.fileInvoiceDollar,
          'color': const Color(0xFF26A69A), // Teal Green
        };
      case 'Kesehatan':
        return {
          'icon': FontAwesomeIcons.stethoscope,
          'color': const Color(0xFFEF5350), // Soft Red
        };
      case 'Lainnya':
        return {
          'icon': FontAwesomeIcons.ellipsis,
          'color': const Color(0xFF78909C), // Blue Grey
        };
      // Kategori Pemasukan
      case 'Gaji':
        return {
          'icon': FontAwesomeIcons.moneyBillWave,
          'color': const Color(0xFF43A047), // Green
        };
      case 'Bonus':
        return {
          'icon': FontAwesomeIcons.gift,
          'color': const Color(0xFF81C784), // Light Green
        };
      case 'Investasi':
        return {
          'icon': FontAwesomeIcons.chartLine,
          'color': const Color(0xFF00897B), // Teal
        };
      default:
        return {
          'icon': FontAwesomeIcons.layerGroup,
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

  static const List<dynamic> planIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.car,
    FontAwesomeIcons.laptop,
    FontAwesomeIcons.plane,
    FontAwesomeIcons.graduationCap,
    FontAwesomeIcons.heart,
    FontAwesomeIcons.mobileScreen,
    FontAwesomeIcons.motorcycle,
    FontAwesomeIcons.piggyBank,
    FontAwesomeIcons.cartShopping,
    FontAwesomeIcons.bowlFood,
    FontAwesomeIcons.film,
  ];

  static dynamic getPlanIcon(int codePoint) {
    try {
      return planIcons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (e) {
      return FontAwesomeIcons.circleQuestion;
    }
  }
}

// --- ENUMS ---
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

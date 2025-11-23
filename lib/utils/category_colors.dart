import 'package:flutter/material.dart';

class CategoryColors {
  static const Map<String, Color> colors = {
    'Makanan': Colors.orange,
    'Transportasi': Colors.blue,
    'Belanja': Colors.green,
    'Hiburan': Colors.purple,
    'Tagihan': Colors.red,
    'Kesehatan': Colors.teal,
    'Lainnya': Colors.grey,
  };

  static Color getColor(String category) {
    return colors[category] ?? Colors.black26;
  }
}

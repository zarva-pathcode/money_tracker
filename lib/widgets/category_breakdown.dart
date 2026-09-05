import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/utils/constants.dart';

class CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const CategoryBreakdown({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Sorting: Urutkan dari nominal terbesar ke terkecil
    final sortedEntries =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Formatter Rupiah
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Detail Pengeluaran",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "${sortedEntries.length} Kategori",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List Kategori
        ...sortedEntries.map((entry) {
          final categoryName = entry.key;
          final amount = entry.value;
          final percentage = totalAmount == 0 ? 0.0 : (amount / totalAmount);
          final style = Constants.getCategoryStyle(categoryName);
          final color = style.color;
          final icon = style.icon;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // A. KOTAK IKON
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: FaIcon(icon, color: color, size: 18)),
                ),

                const SizedBox(width: 16),

                // B. INFO TENGAH (Nama & Progress Bar)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "${(percentage * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Visual Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[100],
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // C. NOMINAL (Kanan)
                Text(
                  currencyFormatter.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

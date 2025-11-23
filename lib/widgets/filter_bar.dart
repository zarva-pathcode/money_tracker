import 'package:flutter/material.dart';
import 'package:money_tracker/widgets/filter_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        // Cek apakah ada filter Tanggal atau Harga yang aktif
        final bool hasComplexFilter =
            provider.startDate != null || provider.minAmount != null;

        // Label tombol berdasarkan sorting saat ini
        final String sortLabel = _getLabelForFilter(
          provider.selectedSortFilter,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Judul di Kiri
            const Text(
              "Transaksi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            // Tombol Filter di Kanan
            InkWell(
              onTap: () {
                // Membuka Modal Bottom Sheet yang sudah dibuat sebelumnya
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const FilterBottomSheet(),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: hasComplexFilter ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    // Border jadi biru jika ada filter aktif
                    color:
                        hasComplexFilter ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      // Ikon berubah jika filter aktif
                      hasComplexFilter
                          ? Icons.filter_list_alt
                          : Icons.tune_rounded,
                      size: 16,
                      color:
                          hasComplexFilter
                              ? Colors.blue[700]
                              : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sortLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color:
                            hasComplexFilter
                                ? Colors.blue[700]
                                : Colors.grey[800],
                      ),
                    ),
                    if (hasComplexFilter) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ] else
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLabelForFilter(SortFilter filter) {
    switch (filter) {
      case SortFilter.newest:
        return "Terbaru";
      case SortFilter.oldest:
        return "Terlama";
      case SortFilter.largest:
        return "Terbesar";
      case SortFilter.smallest:
        return "Terkecil";
    }
  }
}

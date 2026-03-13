import 'package:flutter/material.dart';
import 'package:money_tracker/providers/expense_provider.dart';
import 'package:money_tracker/utils/constants.dart';
import 'animated_tap.dart';

class MonthFilterSelector extends StatefulWidget {
  final ExpenseProvider provider;

  const MonthFilterSelector({super.key, required this.provider});

  @override
  State<MonthFilterSelector> createState() => _MonthFilterSelectorState();
}

class _MonthFilterSelectorState extends State<MonthFilterSelector> {
  final ScrollController _scrollController = ScrollController();

  // List opsi yang sama dengan sebelumnya
  late List<MonthFilter> _options;

  @override
  void initState() {
    super.initState();
    _options = [
      MonthFilter.all,
      ...MonthFilter.values.where((m) => m != MonthFilter.all),
    ];

    // Scroll ke posisi awal setelah frame pertama dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(covariant MonthFilterSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika filter berubah dari luar (misal reset), scroll lagi
    if (oldWidget.provider.selectedMonthFilter !=
        widget.provider.selectedMonthFilter) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    // 1. Cari index bulan yang dipilih
    final selectedIndex = _options.indexOf(widget.provider.selectedMonthFilter);

    if (selectedIndex != -1) {
      // 2. Estimasi lebar item (Text + Padding + Margin)
      // Anggaplah rata-rata lebar badge sekitar 70-80 pixel
      const double itemWidth = 75.0;
      final double screenWidth = MediaQuery.of(context).size.width;

      // 3. Hitung posisi agar item berada di tengah layar
      // Rumus: (Posisi Item) - (Setengah Layar) + (Setengah Item)
      double targetOffset =
          (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      // Pastikan tidak overscroll ke kiri (negatif) atau kanan (melebihi konten)
      final maxScroll = _scrollController.position.maxScrollExtent;
      targetOffset = targetOffset.clamp(0.0, maxScroll);

      // 4. Animasi Scroll
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController, // Pasang controller disini
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final month = _options[index];
        final isSelected = widget.provider.selectedMonthFilter == month;

        String label;
        if (month == MonthFilter.all) {
          label = "Semua";
        } else {
          label = Constants.months[month.index].substring(0, 3);
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedTap(
            onTap: () {
              widget.provider.setMonthFilter(month);
              // _scrollToSelected akan dipanggil otomatis oleh didUpdateWidget
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blue[800]! : Colors.grey.shade300,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                        : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:money_tracker/utils/constants.dart';

class MonthPickerButton extends StatelessWidget {
  final MonthFilter selectedMonth;
  final Function(MonthFilter) onMonthChanged;

  const MonthPickerButton({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _MonthPickerSheet(
            selectedMonth: selectedMonth,
            onMonthSelected: (filter) {
              Navigator.pop(context);
              if (filter != selectedMonth) {
                onMonthChanged(filter);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN 1: Logika penyingkatan teks
    String label;
    if (selectedMonth == MonthFilter.all) {
      label = 'Semua'; // Disingkat dari 'Semua Bulan'
    } else {
      // Ambil nama bulan dari constants
      String fullName = Constants.months[selectedMonth.index];
      // Ambil 3 huruf pertama (Contoh: September -> Sep)
      label = fullName.length > 3 ? fullName.substring(0, 3) : fullName;
    }

    return InkWell(
      onTap: () => _showMonthPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // Mengurangi padding horizontal agar lebih compact
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Penting agar tidak stretch
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: Colors.blue[800],
            ),
            const SizedBox(width: 6),

            // PERBAIKAN 2: Mencegah overflow dengan Flexible
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis, // Titik-titik jika masih kepanjangan
              ),
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

// --- INTERNAL WIDGET: BOTTOM SHEET CONTENT (SAMA SEPERTI SEBELUMNYA) ---
class _MonthPickerSheet extends StatelessWidget {
  final MonthFilter selectedMonth;
  final Function(MonthFilter) onMonthSelected;

  const _MonthPickerSheet({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pilih Periode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${DateTime.now().year}",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAllMonthsOption(),
          const SizedBox(height: 20),
          const Text(
            "Bulan",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthsOnly =
                  MonthFilter.values
                      .where((m) => m != MonthFilter.all)
                      .toList();
              final monthEnum = monthsOnly[index];
              return _buildMonthChip(monthEnum);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllMonthsOption() {
    final isSelected = selectedMonth == MonthFilter.all;
    return InkWell(
      onTap: () => onMonthSelected(MonthFilter.all),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[800]! : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          "Tampilkan Semua Bulan",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthChip(MonthFilter month) {
    final isSelected = month == selectedMonth;
    // Pastikan di grid juga disingkat biar rapi (Jan, Feb)
    String shortName = Constants.months[month.index];
    if (shortName.length > 3) shortName = shortName.substring(0, 3);

    return InkWell(
      onTap: () => onMonthSelected(month),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          shortName.toUpperCase(), // Biar kapital semua (JAN, FEB)
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

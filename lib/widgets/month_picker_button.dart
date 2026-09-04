import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    // Label ringkas: 'Semua' atau 3 huruf pertama nama bulan.
    String label;
    if (selectedMonth == MonthFilter.all) {
      label = 'Semua';
    } else {
      final fullName = Constants.months[selectedMonth.index];
      label = fullName.length > 3 ? fullName.substring(0, 3) : fullName;
    }

    return InkWell(
      onTap: () => _showMonthPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

// --- BOTTOM SHEET PILIH PERIODE (DESAIN BARU) ---
class _MonthPickerSheet extends StatelessWidget {
  final MonthFilter selectedMonth;
  final Function(MonthFilter) onMonthSelected;

  const _MonthPickerSheet({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = MonthFilter.values[now.month - 1];
    // Bulan lalu dengan wrap-around Januari -> Desember.
    final lastMonth = MonthFilter.values[(now.month + 10) % 12];
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gagang tarik
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Judul + badge tahun
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pilih Periode",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${now.year}",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pintasan cepat
            Row(
              children: [
                _buildShortcut(
                  context,
                  icon: FontAwesomeIcons.calendarDay,
                  label: 'Bulan Ini',
                  selected: selectedMonth == thisMonth,
                  onTap: () => onMonthSelected(thisMonth),
                ),
                const SizedBox(width: 10),
                _buildShortcut(
                  context,
                  icon: FontAwesomeIcons.clockRotateLeft,
                  label: 'Bulan Lalu',
                  selected: selectedMonth == lastMonth,
                  onTap: () => onMonthSelected(lastMonth),
                ),
                const SizedBox(width: 10),
                _buildShortcut(
                  context,
                  icon: FontAwesomeIcons.layerGroup,
                  label: 'Semua',
                  selected: selectedMonth == MonthFilter.all,
                  onTap: () => onMonthSelected(MonthFilter.all),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Bulan",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthEnum = MonthFilter.values[index];
                final isCurrent = monthEnum == thisMonth;
                return _buildMonthTile(
                  context,
                  monthEnum,
                  isSelected: monthEnum == selectedMonth,
                  isCurrent: isCurrent,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Tombol pill pintasan cepat (Bulan Ini / Bulan Lalu / Semua).
  Widget _buildShortcut(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 12,
                color: selected ? primary : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tile bulan dalam grid: selected penuh warna, bulan berjalan ada titik.
  Widget _buildMonthTile(
    BuildContext context,
    MonthFilter month, {
    required bool isSelected,
    required bool isCurrent,
  }) {
    final primary = Theme.of(context).primaryColor;
    String shortName = Constants.months[month.index];
    if (shortName.length > 3) shortName = shortName.substring(0, 3);

    return InkWell(
      onTap: () => onMonthSelected(month),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortName.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            // Penanda titik hijau untuk bulan berjalan.
            if (isCurrent) ...[
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.green[600],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

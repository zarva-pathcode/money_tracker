import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Segmented pill switcher tipe transaksi (dipakai tambah & edit).
class TransactionModeSegment extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onTypeChanged;

  const TransactionModeSegment({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ModeItem(
            selected: currentType == 'expense',
            icon: FontAwesomeIcons.arrowUp,
            label: 'Pengeluaran',
            activeColor: Colors.red[700]!,
            onTap: () => onTypeChanged('expense'),
          ),
          _ModeItem(
            selected: currentType == 'income',
            icon: FontAwesomeIcons.arrowDown,
            label: 'Pemasukan',
            activeColor: Colors.green[700]!,
            onTap: () => onTypeChanged('income'),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final bool selected;
  final FaIconData icon;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 13,
                color: selected ? activeColor : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

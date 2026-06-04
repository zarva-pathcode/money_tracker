import 'package:flutter/material.dart';

class TransactionTypeToggle extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onTypeChanged;

  const TransactionTypeToggle({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildItem("Pengeluaran", 'expense', Colors.red[700]!),
          _buildItem("Pemasukan", 'income', Colors.green[700]!),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String type, Color activeColor) {
    final isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/constants.dart';

class CategoryPicker extends StatelessWidget {
  final String selectedCategory;
  final String transactionType;
  final ValueChanged<String> onCategoryChanged;

  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.transactionType,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = transactionType == 'expense'
        ? Constants.expenseCategories
        : Constants.incomeCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Kategori",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: categories
              .map((category) => _buildItem(category))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildItem(String category) {
    final isSelected = selectedCategory == category;
    final style = Constants.getCategoryStyle(category);
    final color = style.color;
    final icon = style.icon;

    return GestureDetector(
      onTap: () => onCategoryChanged(category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[100]!,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

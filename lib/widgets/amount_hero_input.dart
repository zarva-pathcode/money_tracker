import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Kartu hero input nominal: angka besar + tombol reset + pill cepat.
/// Mendengarkan [controller] via ValueListenableBuilder sehingga hanya
/// kartu ini yang rebuild saat angka berubah (dipakai tambah & edit).
class AmountHeroInput extends StatelessWidget {
  final TextEditingController controller;
  final String transactionType;
  final VoidCallback onTapAmount;
  final VoidCallback onClear;
  final ValueChanged<int> onQuickAdd;

  const AmountHeroInput({
    super.key,
    required this.controller,
    required this.transactionType,
    required this.onTapAmount,
    required this.onClear,
    required this.onQuickAdd,
  });

  static const _quickValues = <int>[10000, 20000, 50000, 100000];
  static const _quickLabels = <String>['+10rb', '+20rb', '+50rb', '+100rb'];

  @override
  Widget build(BuildContext context) {
    final isExpense = transactionType == 'expense';
    final accent = isExpense ? Colors.red[700]! : Colors.green[700]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Nominal Pengeluaran' : 'Nominal Pemasukan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              // Tombol reset nominal, muncul hanya jika ada angka.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final hasValue =
                      Formatters.parseFormattedNumber(value.text) > 0;
                  if (!hasValue) return const SizedBox.shrink();
                  return InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Angka besar, tap untuk memunculkan keyboard numerik.
          GestureDetector(
            onTap: onTapAmount,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final text = value.text.isEmpty ? '0' : value.text;
                return Text(
                  'Rp $text',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: accent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Pill pintasan nominal cepat.
          Row(
            children: List.generate(_quickValues.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _quickValues.length - 1 ? 0 : 8,
                  ),
                  child: InkWell(
                    onTap: () => onQuickAdd(_quickValues[index]),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _quickLabels[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

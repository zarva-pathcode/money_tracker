import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  SortFilter? _tempSort;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    _tempSort = provider.selectedSortFilter;
    // Kita tidak load DateRange lagi karena sudah di-handle oleh Badge Bulan
    if (provider.minAmount != null)
      _minController.text = provider.minAmount!.toStringAsFixed(0);
    if (provider.maxAmount != null)
      _maxController.text = provider.maxAmount!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Header + tombol reset cepat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filter & Urutkan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: _resetFilter,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Kartu urutan transaksi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Urutkan Transaksi",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: [
                        _buildSortTile(
                          "Terbaru",
                          SortFilter.newest,
                          FontAwesomeIcons.arrowDownWideShort,
                        ),
                        _buildSortTile(
                          "Terlama",
                          SortFilter.oldest,
                          FontAwesomeIcons.arrowUpWideShort,
                        ),
                        _buildSortTile(
                          "Terbesar",
                          SortFilter.largest,
                          FontAwesomeIcons.arrowTrendUp,
                        ),
                        _buildSortTile(
                          "Terkecil",
                          SortFilter.smallest,
                          FontAwesomeIcons.arrowTrendDown,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),

              // 2. Kartu rentang nominal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rentang Nominal",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAmountField(
                            controller: _minController,
                            label: "Min",
                            hint: "0",
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            width: 16,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildAmountField(
                            controller: _maxController,
                            label: "Max",
                            hint: "Tanpa batas",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pintasan rentang cepat
                    Row(
                      children: [
                        _buildRangeShortcut('< 50rb', 0, 50000),
                        const SizedBox(width: 8),
                        _buildRangeShortcut('50–200rb', 50000, 200000),
                        const SizedBox(width: 8),
                        _buildRangeShortcut('> 200rb', 200000, null),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: 80.ms,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 16),

              // Tombol terapkan full-width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text(
                    "Terapkan Filter",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilter() {
    setState(() {
      _tempSort = SortFilter.newest;
      _minController.clear();
      _maxController.clear();
    });
  }

  void _applyFilter() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (_tempSort != null) provider.setSortFilter(_tempSort!);

    final min = double.tryParse(_minController.text.replaceAll('.', ''));
    final max = double.tryParse(_maxController.text.replaceAll('.', ''));

    provider.setPriceRange(min, max);

    Navigator.pop(context);
  }

  /// Tile pilihan urutan berikon dalam grid 2x2.
  Widget _buildSortTile(String label, SortFilter value, dynamic icon) {
    final isSelected = _tempSort == value;
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () => setState(() => _tempSort = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 14,
              color: isSelected ? primary : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Field nominal dengan prefix Rp dan format ribuan otomatis.
  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final primary = Theme.of(context).primaryColor;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: "Rp ",
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        // Format pemisah ribuan otomatis saat mengetik.
        final formatted = Formatters.formatNumberInput(value);
        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }

  /// Pill pintasan rentang nominal cepat.
  Widget _buildRangeShortcut(String label, double min, double? max) {
    final primary = Theme.of(context).primaryColor;
    final isActive =
        _minController.text == (min > 0 ? Formatters.formatNumberInput(min.toInt().toString()) : '') &&
        _maxController.text ==
            (max != null ? Formatters.formatNumberInput(max.toInt().toString()) : '');
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _minController.text =
                min > 0 ? Formatters.formatNumberInput(min.toInt().toString()) : '';
            _maxController.text =
                max != null ? Formatters.formatNumberInput(max.toInt().toString()) : '';
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? primary : Colors.grey.shade200,
              width: isActive ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? primary : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

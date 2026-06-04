import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:money_tracker/models/plan_item.dart';
import 'package:money_tracker/services/overspend_service.dart';
import 'package:money_tracker/utils/formatters.dart';

class OverspendBottomSheet extends StatefulWidget {
  final double shortfall;
  final List<PlanItem> plans;
  final double totalPlansBalance;

  const OverspendBottomSheet({
    super.key,
    required this.shortfall,
    required this.plans,
    required this.totalPlansBalance,
  });

  @override
  State<OverspendBottomSheet> createState() => _OverspendBottomSheetState();
}

class _OverspendBottomSheetState extends State<OverspendBottomSheet> {
  late Map<String, double> _allocations;
  late Map<String, bool> _selected;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _allocations = {};
    _selected = {};
    _controllers = {};

    _allocations = OverspendService.calculateProportionalAllocation(
      plans: widget.plans,
      shortfall: widget.shortfall,
      totalPlansBalance: widget.totalPlansBalance,
    );

    for (final plan in widget.plans) {
      final amount = _allocations[plan.id] ?? 0;
      _selected[plan.id] = amount > 0;
      _controllers[plan.id] = TextEditingController(
        text: amount > 0 ? Formatters.formatNumberInput(amount.toStringAsFixed(0)) : '',
      );
    }
  }

  void _rebalance() {
    final selectedIds = _selected.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedIds.isEmpty) return;

    final selectedPlans = widget.plans.where((p) => selectedIds.contains(p.id)).toList();
    final selectedAllocations = <String, double>{};
    for (final id in selectedIds) {
      selectedAllocations[id] = _allocations[id] ?? 0;
    }

    final rebalanced = OverspendService.calculateProportionalAllocation(
      plans: selectedPlans,
      shortfall: widget.shortfall,
      totalPlansBalance:
          selectedPlans.fold<double>(0, (sum, p) => sum + p.currentAmount),
    );

    for (final id in selectedIds) {
      _allocations[id] = rebalanced[id] ?? 0;
      final amount = _allocations[id]!;
      _controllers[id]?.text = amount > 0
          ? Formatters.formatNumberInput(amount.toStringAsFixed(0))
          : '';
    }
  }

  void _togglePlan(String id) {
    setState(() {
      _selected[id] = !_selected[id]!;
      if (!_selected[id]!) {
        _allocations[id] = 0;
        _controllers[id]?.text = '';
      } else {
        final plan = widget.plans.firstWhere((p) => p.id == id);
        final autoAmount = plan.currentAmount > widget.shortfall
            ? widget.shortfall
            : plan.currentAmount;
        _allocations[id] = autoAmount;
        _controllers[id]?.text = Formatters.formatNumberInput(autoAmount.toStringAsFixed(0));
        _rebalance();
      }
    });
  }

  void _updateAmount(String id, String value) {
    final amount = Formatters.parseFormattedNumber(value);
    final plan = widget.plans.firstWhere((p) => p.id == id);
    final clamped = amount.clamp(0.0, plan.currentAmount);
    setState(() {
      _allocations[id] = clamped;
      _controllers[id]?.text = clamped > 0
          ? Formatters.formatNumberInput(clamped.toStringAsFixed(0))
          : '';
      _selected[id] = clamped > 0;
    });
  }

  double get _totalAllocated {
    return _allocations.values.fold(0.0, (sum, v) => sum + v);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAllocated = _totalAllocated;
    final isMatch = (totalAllocated - widget.shortfall).abs() < 1 && totalAllocated > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Bulan Ini Tidak Cukup',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kekurangan ${Formatters.formatCurrency(widget.shortfall)}',
                              style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tidak ada tabungan untuk ditarik',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            )
          else
            ...widget.plans.map((plan) {
              final isSelected = _selected[plan.id] ?? false;
              final controller = _controllers[plan.id]!;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue[200]! : Colors.grey[200]!,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _togglePlan(plan.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Saldo: ${Formatters.formatCurrency(plan.currentAmount)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: controller,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                prefixText: 'Rp ',
                                prefixStyle: TextStyle(fontSize: 12, color: Colors.blue[600]),
                              ),
                              onChanged: (v) => _updateAmount(plan.id, v),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMatch ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isMatch ? Icons.check_circle : Icons.error,
                  color: isMatch ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total ditarik: ${Formatters.formatCurrency(totalAllocated)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatch ? Colors.green[800] : Colors.red[800],
                    fontSize: 13,
                  ),
                ),
                if (!isMatch && totalAllocated > 0)
                  Text(
                    ' (kurang ${Formatters.formatCurrency(widget.shortfall - totalAllocated)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isMatch
                        ? () => Navigator.pop(context, _allocations)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Konfirmasi & Simpan'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

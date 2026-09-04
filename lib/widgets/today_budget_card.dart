import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'animated_tap.dart';

class TodayBudgetCard extends StatelessWidget {
  const TodayBudgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    if (budgetProvider.budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final info = budgetProvider.getSmartDailyBudgetInfo(
      settings.periodStartDay,
    );

    final isOver = info.globalRemainingToday < 0;
    final progress = info.progress;

    final cardBg =
        isOver
            ? const Color(0xFFFFF1F2)
            : (progress > 0.85
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFF0FDF4));

    final borderColor =
        isOver
            ? const Color(0xFFFECDD3)
            : (progress > 0.85
                ? const Color(0xFFFDE68A)
                : const Color(0xFFBBF7D0));

    final statusColor =
        isOver
            ? const Color(0xFFE11D48)
            : (progress > 0.85
                ? const Color(0xFFD97706)
                : const Color(0xFF16A34A));

    final statusLabel =
        isOver
            ? 'Over Budget (${Formatters.formatRupiah(info.globalRemainingToday.abs())})'
            : 'Sisa Jatah: ${Formatters.formatRupiah(info.globalRemainingToday)}';

    return AnimatedTap(
      onTap: () => _showBreakdownBottomSheet(context, info),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        isOver
                            ? FontAwesomeIcons.triangleExclamation
                            : FontAwesomeIcons.shieldHalved,
                        size: 14,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Jatah Hari Ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  Formatters.formatRupiah(info.globalSpentToday),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isOver ? const Color(0xFFBE123C) : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  ' / ${Formatters.formatRupiah(info.globalDailyAllowance)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),

            // Footer Subtitle + Detail Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sisa ${info.remainingDays} hari • Re-balance otomatis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Breakdown',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 10,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakdownBottomSheet(
    BuildContext context,
    SmartDailyBudgetInfo info,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BreakdownBottomSheet(info: info),
    );
  }
}

class _BreakdownBottomSheet extends StatelessWidget {
  final SmartDailyBudgetInfo info;

  const _BreakdownBottomSheet({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Detail Jatah Harian per Kategori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rollover otomatis menyesuaikan sisa hari periode (${info.remainingDays} hari tersisa)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          if (info.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada kategori budget yang diatur.'),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: info.categories.length,
                separatorBuilder: (context, index) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = info.categories[index];
                  final isCatOver = item.isOver;
                  final style = Constants.getCategoryStyle(item.category);
                  final catColor = style['color'] as Color;
                  final catIcon = style['icon'] as FaIconData;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(catIcon, size: 16, color: catColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Builder(
                              builder: (context) {
                                String label = 'Target Harian';
                                String unit = '/hr';
                                if (item.granularity == 'weekly') {
                                  label = 'Target Mingguan';
                                  unit = '/mgg';
                                } else if (item.granularity == 'monthly') {
                                  label = 'Target Bulanan';
                                  unit = '/bln';
                                }
                                return Text(
                                  '$label: ${Formatters.formatRupiah(item.dailyAllowance)}$unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatRupiah(item.spentToday),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color:
                                  isCatOver
                                      ? Colors.red.shade700
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCatOver
                                ? 'Over ${Formatters.formatRupiah(item.remainingToday.abs())}'
                                : 'Sisa ${Formatters.formatRupiah(item.remainingToday)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isCatOver
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

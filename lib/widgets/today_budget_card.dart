import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final isWarning = !isOver && progress > 0.85;

    final statusColor =
        isOver
            ? const Color(0xFFE11D48)
            : (isWarning ? const Color(0xFFD97706) : const Color(0xFF16A34A));
    final statusBg =
        isOver
            ? const Color(0xFFFFF1F2)
            : (isWarning ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4));

    final statusLabel =
        isOver
            ? 'Lebih ${Formatters.formatRupiah(info.globalRemainingToday.abs())}'
            : 'Sisa ${Formatters.formatRupiah(info.globalRemainingToday)}';

    return AnimatedTap(
      onTap: () => _showBreakdownBottomSheet(context, info),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: ikon glow + judul + badge status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FaIcon(
                    isOver
                        ? FontAwesomeIcons.triangleExclamation
                        : FontAwesomeIcons.shieldHalved,
                    size: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jatah Belanja Hari Ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOver
                            ? 'Melebihi batas harian'
                            : (isWarning
                                ? 'Mendekati batas harian'
                                : 'Belanja aman hari ini'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Hero angka: terpakai / jatah harian
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  Formatters.formatRupiah(info.globalSpentToday),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  ' / ${Formatters.formatRupiah(info.globalDailyAllowance)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar modern 8px
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),

            // Footer: info periode + tombol rincian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Sisa ${info.remainingDays} hari • Re-balance otomatis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rincian',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
    final isOver = info.globalRemainingToday < 0;
    final statusColor =
        isOver ? const Color(0xFFE11D48) : const Color(0xFF16A34A);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Gagang tarik
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Judul + deskripsi rollover
                    const Text(
                      'Rincian Jatah Harian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut),
                    const SizedBox(height: 4),
                    Text(
                      'Rollover otomatis • ${info.remainingDays} hari tersisa di periode ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: 60.ms,
                          duration: 300.ms,
                          curve: Curves.easeOut,
                        ),
                    const SizedBox(height: 14),
                    // Kartu ringkasan total harian
                    _SummaryCard(info: info, statusColor: statusColor)
                        .animate()
                        .fadeIn(
                          delay: 120.ms,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          delay: 120.ms,
                          duration: 350.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    const SizedBox(height: 16),
                    // Judul daftar kategori
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jatah per Kategori',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${info.categories.length} kategori',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (info.categories.isEmpty)
                      _emptyState()
                    else
                      ...info.categories.asMap().entries.map((entry) {
                        final item = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                entry.key == info.categories.length - 1
                                    ? 0
                                    : 10,
                          ),
                          child: _CategoryTile(item: item)
                              .animate()
                              .fadeIn(
                                delay: (180 + entry.key * 50).ms,
                                duration: 300.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.12,
                                end: 0,
                                delay: (180 + entry.key * 50).ms,
                                duration: 300.ms,
                                curve: Curves.easeOutQuad,
                              ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.wallet,
              size: 24,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada kategori budget yang diatur',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan total harian: terpakai / jatah / sisa global.
class _SummaryCard extends StatelessWidget {
  final SmartDailyBudgetInfo info;
  final Color statusColor;

  const _SummaryCard({required this.info, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final isOver = info.globalRemainingToday < 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.14),
            statusColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              label: 'Terpakai',
              value: Formatters.formatRupiah(info.globalSpentToday),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _summaryItem(
              label: 'Jatah Hari Ini',
              value: Formatters.formatRupiah(info.globalDailyAllowance),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _summaryItem(
              label: isOver ? 'Lebih' : 'Sisa',
              value: Formatters.formatRupiah(
                info.globalRemainingToday.abs(),
              ),
              valueColor: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Tile kartu per kategori: ikon + target + progres mini + sisa.
class _CategoryTile extends StatelessWidget {
  final CategoryAllowanceInfo item;

  const _CategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCatOver = item.isOver;
    final style = Constants.getCategoryStyle(item.category);
    final catColor = style['color'] as Color;
    final catIcon = style['icon'] as FaIconData;

    String targetLabel = 'Target Harian';
    String unit = '/hr';
    if (item.granularity == 'weekly') {
      targetLabel = 'Target Mingguan';
      unit = '/mgg';
    } else if (item.granularity == 'monthly') {
      targetLabel = 'Target Bulanan';
      unit = '/bln';
    }

    final badgeColor =
        isCatOver ? Colors.red.shade700 : Colors.green.shade700;
    final badgeBg = isCatOver ? Colors.red[50]! : Colors.green[50]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FaIcon(catIcon, size: 18, color: catColor),
                ),
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
                    Text(
                      '$targetLabel: ${Formatters.formatRupiah(item.dailyAllowance)}$unit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatRupiah(item.spentToday),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCatOver
                          ? 'Over ${Formatters.formatRupiah(item.remainingToday.abs())}'
                          : 'Sisa ${Formatters.formatRupiah(item.remainingToday)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(
                isCatOver ? Colors.red.shade600 : catColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

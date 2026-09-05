import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

/// Bottom sheet drill-down: menampilkan seluruh transaksi dalam satu
/// kategori pada periode terpilih, beserta ringkasan statistiknya.
class CategoryDetailBottomSheet extends StatelessWidget {
  final String categoryName;
  final List<Expense> transactions;
  final String type;
  final String periodLabel;
  final double categoryTotal;
  final double grandTotal;
  final double? budgetLimit;

  const CategoryDetailBottomSheet({
    super.key,
    required this.categoryName,
    required this.transactions,
    required this.type,
    required this.periodLabel,
    required this.categoryTotal,
    required this.grandTotal,
    this.budgetLimit,
  });

  /// Menampilkan sheet dari halaman laporan.
  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required List<Expense> transactions,
    required String type,
    required String periodLabel,
    required double categoryTotal,
    required double grandTotal,
    double? budgetLimit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDetailBottomSheet(
        categoryName: categoryName,
        transactions: transactions,
        type: type,
        periodLabel: periodLabel,
        categoryTotal: categoryTotal,
        grandTotal: grandTotal,
        budgetLimit: budgetLimit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Constants.getCategoryStyle(categoryName);
    final color = style.color;
    final icon = style.icon;
    final isExpense = type == 'expense';

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final compact = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

    final count = transactions.length;
    final average = count > 0 ? categoryTotal / count : 0.0;
    final biggest = transactions.fold<double>(
      0,
      (max, e) => e.amount > max ? e.amount : max,
    );
    final percent = grandTotal > 0 ? categoryTotal / grandTotal : 0.0;
    final amountColor = isExpense ? Colors.red[700]! : Colors.green[700]!;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                    // 1. Kartu hero kategori
                    _HeroCard(
                      categoryName: categoryName,
                      periodLabel: periodLabel,
                      categoryTotal: categoryTotal,
                      percent: percent,
                      color: color,
                      icon: icon,
                      currency: currency,
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    // 2. Kartu progres anggaran (jika ada budget)
                    if (budgetLimit != null && budgetLimit! > 0) ...[
                      const SizedBox(height: 12),
                      _BudgetCard(
                        spent: categoryTotal,
                        limit: budgetLimit!,
                        currency: currency,
                      )
                          .animate()
                          .fadeIn(
                            delay: 80.ms,
                            duration: 350.ms,
                            curve: Curves.easeOut,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            delay: 80.ms,
                            duration: 350.ms,
                            curve: Curves.easeOutQuad,
                          ),
                    ],
                    // 3. Kartu statistik mini
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatCard(
                          icon: FontAwesomeIcons.receipt,
                          label: 'Transaksi',
                          value: '$count',
                          color: color,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          icon: FontAwesomeIcons.chartColumn,
                          label: 'Rata-rata',
                          value: compact.format(average),
                          color: color,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          icon: FontAwesomeIcons.trophy,
                          label: 'Terbesar',
                          value: compact.format(biggest),
                          color: color,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(
                          delay: 160.ms,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          delay: 160.ms,
                          duration: 350.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    // 4. Judul daftar transaksi
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Semua transaksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count item',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 5. Daftar transaksi sebagai kartu tile
                    if (count == 0)
                      _EmptyState(color: color)
                    else
                      ...transactions.asMap().entries.map((entry) {
                        final tx = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == transactions.length - 1
                                ? 0
                                : 10,
                          ),
                          child: _TransactionTile(
                            tx: tx,
                            color: color,
                            amountColor: amountColor,
                            amountText:
                                '${isExpense ? '−' : '+'} ${currency.format(tx.amount)}',
                            dateText: dateFormat.format(tx.date),
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
}

/// Kartu hero: identitas kategori + total belanja + badge persentase.
class _HeroCard extends StatelessWidget {
  final String categoryName;
  final String periodLabel;
  final double categoryTotal;
  final double percent;
  final Color color;
  final dynamic icon;
  final NumberFormat currency;

  const _HeroCard({
    required this.categoryName,
    required this.periodLabel,
    required this.categoryTotal,
    required this.percent,
    required this.color,
    required this.icon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ikon kategori solid dengan bayangan lembut
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: FaIcon(icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badge periode dengan ikon kalender
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            periodLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Badge persentase
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Total belanja',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            currency.format(categoryTotal),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu progres pemakaian anggaran kategori + badge status.
class _BudgetCard extends StatelessWidget {
  final double spent;
  final double limit;
  final NumberFormat currency;

  const _BudgetCard({
    required this.spent,
    required this.limit,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / limit).clamp(0.0, 1.0);
    final remaining = limit - spent;
    final String status;
    final Color statusColor;
    final Color statusBg;
    if (progress >= 1.0) {
      status = 'Over Budget';
      statusColor = Colors.red[700]!;
      statusBg = Colors.red[50]!;
    } else if (progress >= 0.8) {
      status = 'Waspada';
      statusColor = Colors.orange[800]!;
      statusBg = Colors.orange[50]!;
    } else {
      status = 'Aman';
      statusColor = Colors.green[700]!;
      statusBg = Colors.green[50]!;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anggaran kategori',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: statusColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining >= 0
                ? 'Terpakai ${currency.format(spent)} dari ${currency.format(limit)} • Sisa ${currency.format(remaining)}'
                : 'Terpakai ${currency.format(spent)} dari ${currency.format(limit)} • Lebih ${currency.format(-remaining)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Kartu statistik mini (ikon + nilai + label).
class _StatCard extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, size: 13, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris transaksi sebagai kartu tile putih.
class _TransactionTile extends StatelessWidget {
  final Expense tx;
  final Color color;
  final Color amountColor;
  final String amountText;
  final String dateText;

  const _TransactionTile({
    required this.tx,
    required this.color,
    required this.amountColor,
    required this.amountText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Titik penanda warna kategori
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title.isNotEmpty ? tx.title : tx.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tampilan ramah saat kategori belum punya transaksi.
class _EmptyState extends StatelessWidget {
  final Color color;

  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.basketShopping,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Transaksi kategori ini akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

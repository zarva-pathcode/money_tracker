import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/chart_data.dart';

class ExpenseChart extends StatelessWidget {
  final double totalAmount;
  final List<ChartData> chartData;
  final String period;

  const ExpenseChart({
    super.key,
    required this.totalAmount,
    required this.chartData,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final hasData =
        totalAmount > 0 &&
        chartData.isNotEmpty &&
        chartData[0].category != 'Tidak ada data';

    if (!hasData) return _buildEmptyState();

    return Stack(
      alignment: Alignment.center,
      children: [
        SfCircularChart(
          margin: EdgeInsets.zero,
          tooltipBehavior: TooltipBehavior(
            enable: true,
            // Custom tooltip agar terlihat modern
            color: Colors.black87,
            textStyle: const TextStyle(color: Colors.white),
          ),
          series: <CircularSeries>[
            DoughnutSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.category,
              yValueMapper: (ChartData data, _) => data.amount,
              pointColorMapper: (ChartData data, _) => data.color,

              // STYLING MODERN
              radius: '100%',
              innerRadius: '75%', // Ring tipis
              startAngle: 0,
              endAngle: 360,
              strokeColor: Colors.white, // Pemisah warna putih
              strokeWidth: 3,
              cornerStyle: CornerStyle.bothCurve, // Ujung bulat

              explode: true,
              explodeIndex: 0,
              explodeOffset: '5%',
              dataLabelSettings: const DataLabelSettings(isVisible: false),
            ),
          ],
        ),

        // TEKS TENGAH (Hitam di atas Putih)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Total",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCompactCurrency(totalAmount),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getShortPeriod(period),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[100]!, width: 15),
                ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada data",
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double amount) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 1,
    );
    return "Rp ${formatter.format(amount)}";
  }

  String _getShortPeriod(String fullPeriod) {
    return fullPeriod.replaceAll('Semua Bulan', 'Total');
  }
}

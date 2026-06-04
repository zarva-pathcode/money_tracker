import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../utils/period_helper.dart';

class PdfExportService {
  static const _primary = PdfColor.fromInt(0xFF37474F);
  static const _expenseColor = PdfColor.fromInt(0xFFEF5350);
  static const _incomeColor = PdfColor.fromInt(0xFF66BB6A);
  static const _accent = PdfColor.fromInt(0xFF42A5F5);
  static const _lightBg = PdfColor.fromInt(0xFFFAFAFA);
  static const _cardBg = PdfColor.fromInt(0xFFFFFFFF);
  static const _borderColor = PdfColor.fromInt(0xFFEEEEEE);
  static const _textDark = PdfColor.fromInt(0xFF263238);
  static const _textMedium = PdfColor.fromInt(0xFF78909C);
  static const _textLight = PdfColor.fromInt(0xFFB0BEC5);

  static PdfColor _alpha(PdfColor color, double opacity) {
    final r = (color.red * 255).round();
    final g = (color.green * 255).round();
    final b = (color.blue * 255).round();
    final a = (opacity * 255).round().clamp(0, 255);
    return PdfColor.fromInt((a << 24) | (r << 16) | (g << 8) | b);
  }

  static Future<void> shareReport({
    required List<Expense> allExpenses,
    required List<Expense> filteredExpenses,
    required List<dynamic> plans,
    required int periodStartDay,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _buildReport(
      allExpenses: allExpenses,
      filteredExpenses: filteredExpenses,
      plans: plans,
      periodStartDay: periodStartDay,
      startDate: startDate,
      endDate: endDate,
    );
    await Printing.sharePdf(
      bytes: pdf,
      filename: _generateFilename(startDate, endDate),
    );
  }

  static Future<void> saveReport({
    required List<Expense> allExpenses,
    required List<Expense> filteredExpenses,
    required List<dynamic> plans,
    required int periodStartDay,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _buildReport(
      allExpenses: allExpenses,
      filteredExpenses: filteredExpenses,
      plans: plans,
      periodStartDay: periodStartDay,
      startDate: startDate,
      endDate: endDate,
    );
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/MoneyTracker');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final file = File('${folder.path}/${_generateFilename(startDate, endDate)}.pdf');
    await file.writeAsBytes(pdf);
  }

  /// Simpan PDF ke penyimpanan lokal, lalu bagikan via share sheet.
  /// Mengembalikan path file yang tersimpan.
  static Future<String> shareOrSave({
    required List<Expense> allExpenses,
    required List<Expense> filteredExpenses,
    required List<dynamic> plans,
    required int periodStartDay,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _buildReport(
      allExpenses: allExpenses,
      filteredExpenses: filteredExpenses,
      plans: plans,
      periodStartDay: periodStartDay,
      startDate: startDate,
      endDate: endDate,
    );
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/MoneyTracker');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final filename = '${_generateFilename(startDate, endDate)}.pdf';
    final file = File('${folder.path}/$filename');
    await file.writeAsBytes(pdf);

    await Printing.sharePdf(
      bytes: pdf,
      filename: filename,
    );

    return file.path;
  }

  static String _generateFilename(DateTime? start, DateTime? end) {
    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd');
    final base = 'Laporan_Keuangan';
    if (start != null && end != null) {
      return '${base}_${df.format(start)}_sd_${df.format(end)}';
    }
    return '${base}_${df.format(now)}';
  }

  static Future<Uint8List> _buildReport({
    required List<Expense> allExpenses,
    required List<Expense> filteredExpenses,
    required List<dynamic> plans,
    required int periodStartDay,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID');

    final allTimeIncome = _sumByType(allExpenses, 'income');
    final allTimeExpense = _sumByType(allExpenses, 'expense');
    final allTimeBalance = allTimeIncome - allTimeExpense;
    final totalGoals = plans.fold<double>(0, (s, p) => s + (p.currentAmount as double));
    final totalWealth = allTimeBalance + totalGoals;

    final periodIncome = allExpenses
        .where((e) => e.type == 'income' && PeriodHelper.isInPeriod(e.date, periodStartDay))
        .fold<double>(0, (s, e) => s + e.amount);
    final periodExpense = allExpenses
        .where((e) => e.type == 'expense' && PeriodHelper.isInPeriod(e.date, periodStartDay))
        .fold<double>(0, (s, e) => s + e.amount);
    final periodBalance = periodIncome - periodExpense;

    final currency = (double v) => currencyFormat.format(v);

    pw.Font helveticaBold = pw.Font.helveticaBold();
    pw.Font helvetica = pw.Font.helvetica();

    // ====================================================================
    // PAGE 1: HEADER + SUMMARY CARDS
    // ====================================================================
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 40,
          marginLeft: 30,
          marginRight: 30,
          marginTop: 30,
        ),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Column(
              children: [
                pw.SizedBox(height: 16),
                pw.Text(
                  'LAPORAN KEUANGAN',
                  style: pw.TextStyle(
                    font: helveticaBold,
                    fontSize: 20,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _getPeriodLabel(startDate, endDate, periodStartDay, monthFormat),
                  style: pw.TextStyle(font: helvetica, fontSize: 11, color: _textMedium),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Dicetak: ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: helvetica, fontSize: 10, color: _textLight),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Summary row: wealth | period | all-time
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildSummaryCard('Total Kekayaan', currency(totalWealth), _primary, _lightBg)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildSummaryCard('Saldo Periode', currency(periodBalance), _primary, _lightBg)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildSummaryCard('Saldo Riil', currency(allTimeBalance), _primary, _lightBg)),
            ],
          ),

          pw.SizedBox(height: 16),

          // Sub-row: pemasukan & pengeluaran
          pw.Row(
            children: [
              pw.Expanded(child: _buildMiniCard('Pemasukan', currency(periodIncome), _incomeColor)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildMiniCard('Pengeluaran', currency(periodExpense), _expenseColor)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildMiniCard('Tabungan', currency(totalGoals), _accent)),
            ],
          ),

          pw.SizedBox(height: 24),

          // SECTION: EXPENSE CATEGORY BREAKDOWN
          _sectionTitle('RINCIAN PENGELUARAN PER KATEGORI'),
          pw.SizedBox(height: 8),
          ..._buildCategoryTable(filteredExpenses, 'expense', currency, helvetica, helveticaBold),

          pw.SizedBox(height: 24),

          // SECTION: INCOME CATEGORY BREAKDOWN
          _sectionTitle('RINCIAN PEMASUKAN PER KATEGORI'),
          pw.SizedBox(height: 8),
          ..._buildCategoryTable(filteredExpenses, 'income', currency, helvetica, helveticaBold),

          pw.SizedBox(height: 24),

          // SECTION: MONTHLY TRENDS
          _sectionTitle('TREN BULANAN'),
          pw.SizedBox(height: 8),
          ..._buildMonthlyTable(allExpenses, currency, helvetica, helveticaBold),

          pw.SizedBox(height: 24),

          // SECTION: TOP TRANSACTIONS
          _sectionTitle('TRANSAKSI TERBESAR'),
          pw.SizedBox(height: 8),
          ..._buildTopTransactionsTable(filteredExpenses, currency, helvetica, helveticaBold, dateFormat),

          pw.SizedBox(height: 24),

          // SECTION: GOALS SUMMARY
          _sectionTitle('RINGKASAN TABUNGAN'),
          pw.SizedBox(height: 8),
          if (plans.isEmpty)
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: _lightBg,
        ),
              child: pw.Text('Belum ada tabungan', style: pw.TextStyle(font: helvetica, color: _textMedium)),
            )
          else
            ..._buildGoalsTable(plans, currency, helvetica, helveticaBold),
        ],
      ),
    );

    return doc.save();
  }

  static double _sumByType(List<Expense> expenses, String type) {
    return expenses.where((e) => e.type == type).fold<double>(0, (s, e) => s + e.amount);
  }

  static String _getPeriodLabel(DateTime? start, DateTime? end, int payDay, DateFormat df) {
    if (start != null && end != null) {
      return '${df.format(start)} - ${df.format(end)}';
    }
    if (payDay > 1) {
      return 'Periode: ${PeriodHelper.formatPeriodRange(payDay)}';
    }
    return 'Bulan: ${df.format(DateTime.now())}';
  }

  // ====================================================================
  // WIDGET BUILDERS
  // ====================================================================

  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Money Tracker', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _textLight)),
          pw.Text('Laporan Keuangan', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textLight)),
          pw.Text('Halaman ${context.pageNumber}', style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textLight)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Dihasilkan oleh Money Tracker App',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8, color: _textLight),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(String label, String value, PdfColor color, PdfColor bg) {
    return pw.Container(
      padding: pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textMedium)),
          pw.SizedBox(height: 6),
          pw.Text(value, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildMiniCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: _textMedium)),
          pw.Text(value, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: _textDark),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 50, color: _primary),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static List<pw.Widget> _buildCategoryTable(
    List<Expense> expenses,
    String type,
    String Function(double) currency,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final filtered = expenses.where((e) => e.type == type).toList();
    final totals = <String, double>{};
    for (var e in filtered) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final totalAmount = totals.values.fold<double>(0, (s, v) => s + v);
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return [
        pw.Container(
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _lightBg,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text('Tidak ada data ${type == 'expense' ? 'pengeluaran' : 'pemasukan'}',
              style: pw.TextStyle(font: font, color: _textMedium)),
        ),
      ];
    }

    return [
      // Table header
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 2, child: pw.Text('Kategori', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
            pw.Expanded(flex: 1, child: pw.Text('Jumlah', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 1, child: pw.Text('%', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
      // Rows
      ...sorted.map((entry) {
        final pct = totalAmount > 0 ? (entry.value / totalAmount * 100) : 0.0;
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.3)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 9, color: _textDark))),
              pw.Expanded(flex: 1, child: pw.Text(currency(entry.value), style: pw.TextStyle(font: font, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 1, child: pw.Text('${pct.toStringAsFixed(1)}%', style: pw.TextStyle(font: font, fontSize: 9, color: _textMedium), textAlign: pw.TextAlign.right)),
            ],
          ),
        );
      }),
      // Total row
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: _lightBg,
          borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(6)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 2, child: pw.Text('TOTAL', style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textDark))),
            pw.Expanded(flex: 1, child: pw.Text(currency(totalAmount), style: pw.TextStyle(font: boldFont, fontSize: 10, color: type == 'expense' ? _expenseColor : _incomeColor), textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 1, child: pw.Text('100%', style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textMedium), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildMonthlyTable(
    List<Expense> allExpenses,
    String Function(double) currency,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final year = DateTime.now().year;
    final monthlyExpense = <int, double>{};
    final monthlyIncome = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      monthlyExpense[i] = 0.0;
      monthlyIncome[i] = 0.0;
    }
    for (var e in allExpenses) {
      if (e.date.year != year) continue;
      if (e.type == 'expense') monthlyExpense[e.date.month] = (monthlyExpense[e.date.month] ?? 0) + e.amount;
      if (e.type == 'income') monthlyIncome[e.date.month] = (monthlyIncome[e.date.month] ?? 0) + e.amount;
    }

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return [
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(child: pw.Text('Bulan', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
            pw.Expanded(child: pw.Text('Pemasukan', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
            pw.Expanded(child: pw.Text('Pengeluaran', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
            pw.Expanded(child: pw.Text('Sisa', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
      for (int i = 1; i <= 12; i++)
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: i % 2 == 0 ? _lightBg : _cardBg,
            border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.3)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text(months[i - 1], style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
              pw.Expanded(child: pw.Text(currency(monthlyIncome[i] ?? 0), style: pw.TextStyle(font: font, fontSize: 9, color: _incomeColor), textAlign: pw.TextAlign.right)),
              pw.Expanded(child: pw.Text(currency(monthlyExpense[i] ?? 0), style: pw.TextStyle(font: font, fontSize: 9, color: _expenseColor), textAlign: pw.TextAlign.right)),
              pw.Expanded(child: pw.Text(currency((monthlyIncome[i] ?? 0) - (monthlyExpense[i] ?? 0)), style: pw.TextStyle(font: font, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
            ],
          ),
        ),
      // Total row
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: _lightBg,
          borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(6)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(child: pw.Text('RATA-RATA', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
            pw.Expanded(child: pw.Text(currency(_avg(monthlyIncome)), style: pw.TextStyle(font: boldFont, fontSize: 9, color: _incomeColor), textAlign: pw.TextAlign.right)),
            pw.Expanded(child: pw.Text(currency(_avg(monthlyExpense)), style: pw.TextStyle(font: boldFont, fontSize: 9, color: _expenseColor), textAlign: pw.TextAlign.right)),
            pw.Expanded(child: pw.Text('', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
    ];
  }

  static double _avg(Map<int, double> data) {
    final now = DateTime.now();
    final count = now.month;
    if (count == 0) return 0;
    return data.values.fold<double>(0, (s, v) => s + v) / count;
  }

  static List<pw.Widget> _buildTopTransactionsTable(
    List<Expense> expenses,
    String Function(double) currency,
    pw.Font font,
    pw.Font boldFont,
    DateFormat dateFormat,
  ) {
    final allTx = List<Expense>.from(expenses)..sort((a, b) => b.amount.compareTo(a.amount));
    final top = allTx.take(10).toList();

    if (top.isEmpty) {
      return [
        pw.Container(
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Text('Tidak ada transaksi', style: pw.TextStyle(font: font, color: _textMedium)),
        ),
      ];
    }

    return [
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('Judul', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _textDark))),
            pw.Expanded(flex: 2, child: pw.Text('Kategori', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _textDark), textAlign: pw.TextAlign.center)),
            pw.Expanded(flex: 2, child: pw.Text('Tanggal', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _textDark), textAlign: pw.TextAlign.center)),
            pw.Expanded(flex: 2, child: pw.Text('Jumlah', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _textDark), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
      for (int i = 0; i < top.length; i++)
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: i % 2 == 0 ? _cardBg : _lightBg,
            border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.3)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text(top[i].title, style: pw.TextStyle(font: font, fontSize: 8, color: _textDark), maxLines: 1)),
              pw.Expanded(flex: 2, child: pw.Text(top[i].category, style: pw.TextStyle(font: font, fontSize: 8, color: _textMedium), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text(dateFormat.format(top[i].date), style: pw.TextStyle(font: font, fontSize: 8, color: _textMedium), textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text(
                currency(top[i].amount),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8,
                  color: top[i].type == 'income' ? _incomeColor : _expenseColor,
                ),
                textAlign: pw.TextAlign.right,
              )),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _buildGoalsTable(
    List<dynamic> plans,
    String Function(double) currency,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return [
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('Tabungan', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
            pw.Expanded(flex: 2, child: pw.Text('Progress', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.center)),
            pw.Expanded(flex: 2, child: pw.Text('Target', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
      ...plans.map((plan) {
        final current = plan.currentAmount as double;
        final target = plan.targetAmount as double;
        final pct = target > 0 ? (current / target * 100).clamp(0, 100) : 0.0;
        final color = plan.colorValue != null
            ? PdfColor.fromInt(plan.colorValue as int)
            : _accent;
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(plan.title ?? '', style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark)),
                  pw.Text('${pct.toStringAsFixed(0)}%', style: pw.TextStyle(font: boldFont, fontSize: 9, color: color)),
                ],
              ),
              pw.SizedBox(height: 4),
              // Progress bar
              pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                  color: _borderColor,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: pct / 100 * 380,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(currency(current), style: pw.TextStyle(font: font, fontSize: 8, color: _textMedium)),
                  pw.Text(currency(target), style: pw.TextStyle(font: font, fontSize: 8, color: _textMedium)),
                ],
              ),
            ],
          ),
        );
      }),
    ];
  }
}

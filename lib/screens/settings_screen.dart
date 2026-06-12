import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:money_tracker/screens/monthly_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/plan_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'reminder_settings_screen.dart';
import '../providers/widget_provider.dart';
import '../utils/constants.dart';
import '../models/expense.dart';
import '../services/pdf_export_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final String _privacyPolicyUrl =
      'https://doc-hosting.flycricket.io/money-tracker-privacy-policy/1d30a982-afeb-484e-b862-fafa71e1646b/privacy';

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(_privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_privacyPolicyUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final planProvider = Provider.of<PlanProvider>(context);
    final analysisProvider = Provider.of<AnalysisProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Section Preferensi
          _buildSectionHeader("Preferensi"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.bell,
              iconColor: Colors.blue,
              title: 'Pengingat Harian',
              subtitle: 'Atur jadwal notifikasi harian',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.calendarDay,
              iconColor: Colors.teal,
              title: 'Tanggal Mulai Periode',
              subtitle: settingsProvider.periodStartDay == 1
                  ? 'Default (tanggal 1)'
                  : 'Tanggal ${settingsProvider.periodStartDay} setiap bulan',
              onTap: () => _showPeriodStartPicker(context, settingsProvider),
            ),
            const SizedBox(height: 4),
            _buildToggleTile(
              context,
              icon: FontAwesomeIcons.bell,
              iconColor: Colors.orange,
              title: 'Peringatan Anggaran',
              subtitle: settingsProvider.budgetAlertsEnabled
                  ? 'Aktif'
                  : 'Nonaktif',
              value: settingsProvider.budgetAlertsEnabled,
              onChanged: (val) => settingsProvider.setBudgetAlertsEnabled(val),
            ),
          ]),

          const SizedBox(height: 24),

          // 2. Section Widget
          _buildSectionHeader("Kustomisasi Widget"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.shapes,
              iconColor: Colors.indigo,
              title: 'Widget Home Screen',
              subtitle: 'Atur 3 kategori favorit di widget',
              onTap: () => _showWidgetSettings(context),
            ),
          ]),

          const SizedBox(height: 24),

          // 3. Section Data
          _buildSectionHeader("Manajemen Data"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.fileExport,
              iconColor: Colors.green,
              title: 'Ekspor Data',
              subtitle: 'Backup ke JSON atau CSV',
              onTap: () => _showExportOptions(context, expenseProvider, planProvider, analysisProvider, settingsProvider),
            ),
            const SizedBox(height: 4),
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.fileImport,
              iconColor: Colors.blue,
              title: 'Impor Data',
              subtitle: 'Restore dari file backup',
              onTap: () => _showImportOptions(context, expenseProvider),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader("Tentang & Legalitas"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.shieldHalved,
              iconColor: Colors.blueGrey,
              title: 'Kebijakan Privasi',
              subtitle: 'Ketentuan penggunaan data',
              onTap: () => _launchPrivacyPolicy(),
            ),
          ]),

          const SizedBox(height: 24),

          // 3. Section Danger Zone
          _buildSectionHeader("Zona Berbahaya"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.triangleExclamation,
              iconColor: Colors.red,
              title: 'Hapus Semua Data',
              subtitle: 'Tindakan ini permanen',
              textColor: Colors.red,
              onTap: () => _clearAllData(context, expenseProvider),
            ),
          ]),

          const SizedBox(height: 40),

          Center(
            child: Column(
              children: [
                const Text(
                  "Money Tracker v1.0.0",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dibuat oleh Zarvaism",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required dynamic icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color textColor = Colors.black87,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: FaIcon(icon, color: iconColor, size: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                color: Colors.grey[300],
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: FaIcon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(
    BuildContext context,
    ExpenseProvider expenseProvider,
    PlanProvider planProvider,
    AnalysisProvider analysisProvider,
    SettingsProvider settingsProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  "Ekspor Data",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 24),
                _buildActionBtn(
                  ctx,
                  "Format JSON (Backup)",
                  FontAwesomeIcons.code,
                  Colors.orange,
                  () {
                    Navigator.pop(ctx);
                    _exportToJson(context, expenseProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionBtn(
                  ctx,
                  "Format CSV (Excel)",
                  FontAwesomeIcons.fileExcel,
                  Colors.green,
                  () {
                    Navigator.pop(ctx);
                    _exportToCsv(context, expenseProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionBtn(
                  ctx,
                  "Format PDF (Laporan)",
                  FontAwesomeIcons.filePdf,
                  Colors.red,
                  () {
                    Navigator.pop(ctx);
                    _exportToPdf(
                      context,
                      expenseProvider,
                      planProvider,
                      analysisProvider,
                      settingsProvider,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _formatInfo(ctx),
              ],
            ),
          ),
    );
  }

  void _showImportOptions(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  "Impor Data",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 24),
                _buildActionBtn(
                  ctx,
                  "Dari File JSON",
                  FontAwesomeIcons.fileCode,
                  Theme.of(context).primaryColor,
                  () {
                    Navigator.pop(ctx);
                    _importFromJson(context, provider);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionBtn(
                  ctx,
                  "Dari File CSV",
                  FontAwesomeIcons.fileCsv,
                  Colors.teal,
                  () {
                    Navigator.pop(ctx);
                    _importFromCsv(context, provider);
                  },
                ),
                const SizedBox(height: 24),
                _formatInfo(ctx),
              ],
            ),
          ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    dynamic icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: FaIcon(icon, color: color, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _formatInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "JSON: Cocok untuk backup & restore di aplikasi ini.",
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                Text(
                  "CSV: Cocok untuk dibuka di Excel atau Google Sheets.",
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportToJson(BuildContext context, ExpenseProvider provider) async {
    try {
      final result = await ExportService.exportToJson(provider.allExpenses);
      _showSuccessDialog(
        context,
        'Berhasil Ekspor',
        'File tersimpan di:\n$result',
      );
    } catch (e) {
      _showErrorDialog(context, 'Gagal Ekspor', e.toString());
    }
  }

  void _exportToCsv(BuildContext context, ExpenseProvider provider) async {
    try {
      final result = await ExportService.exportToCsv(provider.allExpenses);
      _showSuccessDialog(
        context,
        'Berhasil Ekspor',
        'File tersimpan di:\n$result',
      );
    } catch (e) {
      _showErrorDialog(context, 'Gagal Ekspor', e.toString());
    }
  }

  void _exportToPdf(
    BuildContext context,
    ExpenseProvider expenseProvider,
    PlanProvider planProvider,
    AnalysisProvider analysisProvider,
    SettingsProvider settingsProvider,
  ) async {
    try {
      if (!context.mounted) return;

      final range = await showDialog<_PdfRange>(
        context: context,
        builder: (ctx) => _PdfRangeDialog(),
      );
      if (range == null) return;

      DateTime? start;
      DateTime? end;
      List<Expense> targetExpenses;

      if (range == _PdfRange.all) {
        targetExpenses = expenseProvider.allExpenses;
      } else {
        if (!context.mounted) return;
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
          locale: const Locale('id', 'ID'),
        );
        if (picked == null) return;
        start = picked.start;
        end = picked.end;
        targetExpenses = expenseProvider.allExpenses.where((e) {
          return e.date.isAfter(start!.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end!.add(const Duration(days: 1)));
        }).toList();
      }

      if (!context.mounted) return;
      final filePath = await PdfExportService.shareOrSave(
        allExpenses: expenseProvider.allExpenses,
        filteredExpenses: targetExpenses,
        plans: planProvider.plans,
        periodStartDay: settingsProvider.periodStartDay,
        startDate: start,
        endDate: end,
      );
      if (context.mounted) {
        final fileName = filePath.split(RegExp(r'[/\\]')).last;
        final folder = filePath.substring(0, filePath.length - fileName.length);
        _showSuccessDialog(
          context,
          'Berhasil Export PDF',
          'File tersimpan di:',
          fileName: fileName,
          folder: folder,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Gagal Export PDF', e.toString());
      }
    }
  }

  void _importFromJson(BuildContext context, ExpenseProvider provider) async {
    try {
      final imported = await ImportService.importFromJson();
      if (imported.isEmpty) {
        _showErrorDialog(context, 'Gagal Impor', 'Tidak ada data valid.');
        return;
      }
      for (var expense in imported) {
        await provider.addExpense(expense);
      }
      _showSuccessDialog(
        context,
        'Berhasil Impor',
        '${imported.length} transaksi ditambahkan.',
      );
    } catch (e) {
      _showErrorDialog(context, 'Gagal Impor', e.toString());
    }
  }

  void _importFromCsv(BuildContext context, ExpenseProvider provider) async {
    try {
      final imported = await ImportService.importFromCsv();
      if (imported.isEmpty) {
        _showErrorDialog(context, 'Gagal Impor', 'Tidak ada data valid.');
        return;
      }
      for (var expense in imported) {
        await provider.addExpense(expense);
      }
      _showSuccessDialog(
        context,
        'Berhasil Impor',
        '${imported.length} transaksi ditambahkan.',
      );
    } catch (e) {
      _showErrorDialog(context, 'Gagal Impor', e.toString());
    }
  }

  void _clearAllData(BuildContext context, ExpenseProvider provider) async {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 32,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Hapus Semua Data?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tindakan ini akan menghapus seluruh riwayat transaksi Anda secara permanen. Data yang hilang tidak dapat dikembalikan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await provider.clearAllExpenses();
                            if (context.mounted) {
                              _showSuccessDialog(
                                context,
                                'Berhasil',
                                'Aplikasi telah di-reset bersih.',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Hapus",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSuccessDialog(BuildContext context, String title, String subtitle, {String? fileName, String? folder}) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: Colors.green,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                if (fileName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (folder != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    folder,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleXmark,
                  color: Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: SelectableText(message),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showWidgetSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Consumer<WidgetProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text(
                      "Kustomisasi Widget",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pilih 3 kategori favorit untuk akses cepat",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(3, (index) {
                      final category = provider.favoriteCategories[index];
                      final style = Constants.getCategoryStyle(category);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: style['color'].withOpacity(0.1),
                            child: FaIcon(
                              style['icon'],
                              color: style['color'],
                              size: 16,
                            ),
                          ),
                          title: Text(
                            "Slot ${index + 1}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const FaIcon(
                            FontAwesomeIcons.pen,
                            size: 14,
                          ),
                          onTap:
                              () =>
                                  _showCategoryPicker(context, index, provider),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Selesai",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    int slotIndex,
    WidgetProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const Text(
                  "Pilih Kategori",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: Constants.expenseCategories.length,
                    itemBuilder: (ctx, index) {
                      final cat = Constants.expenseCategories[index];
                      final style = Constants.getCategoryStyle(cat);
                      return InkWell(
                        onTap: () {
                          provider.updateFavorite(slotIndex, cat);
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: style['color'].withOpacity(0.1),
                              child: FaIcon(
                                style['icon'],
                                color: style['color'],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat,
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showPeriodStartPicker(BuildContext context, SettingsProvider settingsProvider) {
    int selectedDay = settingsProvider.periodStartDay;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text(
                      "Tanggal Mulai Periode",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sesuaikan dengan tanggal gajian kamu",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        diameterRatio: 2,
                        overAndUnderCenterOpacity: 0.3,
                        onSelectedItemChanged: (index) {
                          setSheetState(() => selectedDay = index + 1);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final day = index + 1;
                            final isSelected = day == selectedDay;
                            final label = day == 1 ? 'Tanggal 1 (Default)' : 'Tanggal $day';
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                          childCount: 31,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (selectedDay != 1)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() => selectedDay = 1);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Reset ke Default",
                                style: TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ),
                        if (selectedDay != 1) const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await settingsProvider.setPeriodStartDay(selectedDay);
                              if (context.mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Simpan",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
    );
  }
}

enum _PdfRange { all, custom }

class _PdfRangeDialog extends StatelessWidget {
  const _PdfRangeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rentang Laporan'),
      content: const Text('Pilih data yang ingin dimasukkan ke laporan PDF:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _PdfRange.all),
          child: const Text('Semua Data'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _PdfRange.custom),
          child: const Text('Pilih Rentang'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/plan_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'reminder_settings_screen.dart';
import 'subscription_screen.dart';
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
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── App Identity Hero ──
          _buildAppHeroCard(context, primary)
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // 1. Preferensi
          _buildSectionHeader("Preferensi")
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
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
            _buildDivider(),
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
            _buildDivider(),
            _buildToggleTile(
              context,
              icon: FontAwesomeIcons.bell,
              iconColor: Colors.orange,
              title: 'Peringatan Anggaran',
              subtitle: settingsProvider.budgetAlertsEnabled ? 'Aktif' : 'Nonaktif',
              value: settingsProvider.budgetAlertsEnabled,
              onChanged: (val) => settingsProvider.setBudgetAlertsEnabled(val),
            ),
            _buildDivider(),
            _buildToggleTile(
              context,
              icon: settingsProvider.hideAmount ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              iconColor: Colors.deepPurple,
              title: 'Sembunyikan Saldo',
              subtitle:
                  settingsProvider.hideAmount ? 'Saldo disembunyikan • privasi aktif' : 'Saldo terlihat',
              value: settingsProvider.hideAmount,
              onChanged: (val) => settingsProvider.setHideAmount(val),
            ),
            _buildDivider(),
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.repeat,
              iconColor: Colors.indigo,
              title: 'Kelola Langganan Rutin',
              subtitle: 'Atur deteksi & status langganan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // 2. Widget
          _buildSectionHeader("Kustomisasi Widget")
              .animate(delay: 80.ms)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
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

          // 3. Data
          _buildSectionHeader("Manajemen Data")
              .animate(delay: 160.ms)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: FontAwesomeIcons.fileExport,
              iconColor: Colors.green,
              title: 'Ekspor Data',
              subtitle: 'Backup ke JSON / CSV / PDF',
              onTap: () => _showExportOptions(
                  context, expenseProvider, planProvider, analysisProvider, settingsProvider),
            ),
            _buildDivider(),
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

          _buildSectionHeader("Tentang & Legalitas")
              .animate(delay: 240.ms)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
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

          // Danger Zone — container merah lembut
          _buildSectionHeader("Zona Berbahaya")
              .animate(delay: 320.ms)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildSettingTile(
              context,
              icon: FontAwesomeIcons.triangleExclamation,
              iconColor: Colors.red,
              title: 'Hapus Semua Data',
              subtitle: 'Tindakan ini permanen & tidak dapat dibatalkan',
              textColor: Colors.red,
              onTap: () => _clearAllData(context, expenseProvider),
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: Column(
              children: [
                const Text(
                  "Money Tracker v1.0.0",
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dibuat oleh Zarvaism",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Penyimpanan Lokal Aktif',
                          style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAppHeroCard(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FaIcon(FontAwesomeIcons.wallet, color: primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Money Tracker',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text('v1.0.0',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.lock, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Privat & Aman • Penyimpanan Lokal',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100], indent: 76, endIndent: 20);
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
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
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
                  color: iconColor.withValues(alpha: 0.12),
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
                color: iconColor.withValues(alpha: 0.12),
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
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: iconColor,
              activeTrackColor: iconColor.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  // ── Export / Import: format selection cards ──
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
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                const Text("Ekspor Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text("Pilih format yang paling sesuai untuk kebutuhanmu",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 20),
                _buildFormatCard(
                  context,
                  icon: FontAwesomeIcons.code,
                  iconColor: Colors.orange,
                  title: "JSON",
                  subtitle: "Cadangan Lengkap — format standar Money Tracker",
                  badge: "Backup & Restore",
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportToJson(context, expenseProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildFormatCard(
                  context,
                  icon: FontAwesomeIcons.fileExcel,
                  iconColor: Colors.green,
                  title: "CSV",
                  subtitle: "Spreadsheet Excel — tabel rapi siap analisis",
                  badge: "Excel / Sheets",
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportToCsv(context, expenseProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildFormatCard(
                  context,
                  icon: FontAwesomeIcons.filePdf,
                  iconColor: Colors.red,
                  title: "PDF",
                  subtitle: "Dokumen Laporan — siap cetak & bagikan",
                  badge: "Laporan",
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportToPdf(context, expenseProvider, planProvider, analysisProvider, settingsProvider);
                  },
                ),
                const SizedBox(height: 20),
                _formatInfo(ctx),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportOptions(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                const Text("Impor Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text("Pulihkan data dari file cadanganmu",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 20),
                _buildFormatCard(
                  context,
                  icon: FontAwesomeIcons.fileCode,
                  iconColor: Theme.of(context).primaryColor,
                  title: "Dari File JSON",
                  subtitle: "Restore backup standar aplikasi",
                  badge: "JSON",
                  onTap: () {
                    Navigator.pop(ctx);
                    _importFromJson(context, provider);
                  },
                ),
                const SizedBox(height: 12),
                _buildFormatCard(
                  context,
                  icon: FontAwesomeIcons.fileCsv,
                  iconColor: Colors.teal,
                  title: "Dari File CSV",
                  subtitle: "Impor data dari Excel / Sheets",
                  badge: "CSV",
                  onTap: () {
                    Navigator.pop(ctx);
                    _importFromCsv(context, provider);
                  },
                ),
                const SizedBox(height: 20),
                _formatInfo(ctx),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    BuildContext context, {
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: FaIcon(icon, color: iconColor, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: iconColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
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

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mohon tunggu sampai proses selesai.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _importFromJson(BuildContext context, ExpenseProvider provider) async {
    try {
      final imported = await ImportService.importFromJson();
      if (imported.isEmpty) {
        if (context.mounted) {
          _showErrorDialog(context, 'Gagal Impor', 'Tidak ada data valid.');
        }
        return;
      }

      if (context.mounted) {
        _showLoadingDialog(context, "Mengimpor Data...");
      }

      await provider.addAllExpenses(imported);

      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog(
          context,
          'Berhasil Impor',
          '${imported.length} transaksi ditambahkan.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) {
          return route.settings.name != null || route.isFirst;
        });
        _showErrorDialog(context, 'Gagal Impor', e.toString());
      }
    }
  }

  void _importFromCsv(BuildContext context, ExpenseProvider provider) async {
    try {
      final imported = await ImportService.importFromCsv();
      if (imported.isEmpty) {
        if (context.mounted) {
          _showErrorDialog(context, 'Gagal Impor', 'Tidak ada data valid.');
        }
        return;
      }

      if (context.mounted) {
        _showLoadingDialog(context, "Mengimpor Data Csv...");
      }

      await provider.addAllExpenses(imported);

      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog(
          context,
          'Berhasil Impor',
          '${imported.length} transaksi ditambahkan.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        _showErrorDialog(context, 'Gagal Impor', e.toString());
      }
    }
  }

  void _clearAllData(BuildContext context, ExpenseProvider provider) async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  color: Colors.red.withValues(alpha: 0.1),
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

  void _showSuccessDialog(BuildContext context, String title, String subtitle,
      {String? fileName, String? folder}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
      builder: (ctx) => AlertDialog(
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
          constraints: const BoxConstraints(maxHeight: 220),
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
      builder: (ctx) => Consumer<WidgetProvider>(
        builder: (context, provider, child) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                const SizedBox(height: 20),
                // Mini preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: List.generate(3, (i) {
                      final cat = provider.favoriteCategories[i];
                      final st = Constants.getCategoryStyle(cat);
                      final col = st.color;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: col.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              FaIcon(st.icon, color: col, size: 16),
                              const SizedBox(height: 4),
                              Text(cat,
                                  style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold, color: col),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) {
                  final category = provider.favoriteCategories[index];
                  final style = Constants.getCategoryStyle(category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        tileColor: Colors.white,
                        leading: CircleAvatar(
                          backgroundColor: (style.color).withValues(alpha: 0.12),
                          child: FaIcon(
                            style.icon,
                            color: style.color,
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
                        onTap: () => _showCategoryPicker(context, index, provider),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
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
                      elevation: 0,
                    ),
                    child: const Text(
                      "Selesai",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                  ],
                ),
              ),
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
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Pilih Kategori",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text("Tap kategori untuk mengisi slot ${slotIndex + 1}",
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: Constants.expenseCategories.length,
                itemBuilder: (ctx, index) {
                  final cat = Constants.expenseCategories[index];
                  final style = Constants.getCategoryStyle(cat);
                  final isSelected = provider.favoriteCategories[slotIndex] == cat;
                  final col = style.color;
                  return InkWell(
                    onTap: () {
                      provider.updateFavorite(slotIndex, cat);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? col.withValues(alpha: 0.12) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected ? col : Colors.grey[200]!,
                            width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: col.withValues(alpha: 0.12),
                            child: FaIcon(
                              style.icon,
                              color: col,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              cat,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Colors.black87 : Colors.grey[700]),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
    final primary = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      "Sesuaikan dengan tanggal gajian kamu agar saldo periode akurat",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                // Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.circleInfo, size: 16, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Periode berjalan dari tanggal ${selectedDay == 1 ? '1' : selectedDay} bulan ini hingga tanggal ${selectedDay == 1 ? 'akhir bulan' : '${selectedDay - 1} bulan depan'}. Saldo & anggaran akan mengikuti periode ini.",
                          style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quick presets
                Row(
                  children: [
                    _buildPresetChip(context, label: "Tgl 1", day: 1, selected: selectedDay, onTap: () => setSheetState(() => selectedDay = 1)),
                    const SizedBox(width: 8),
                    _buildPresetChip(context, label: "Tgl 25", day: 25, selected: selectedDay, onTap: () => setSheetState(() => selectedDay = 25)),
                    const SizedBox(width: 8),
                    _buildPresetChip(context, label: "Tgl 28", day: 28, selected: selectedDay, onTap: () => setSheetState(() => selectedDay = 28)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 44,
                    diameterRatio: 2,
                    overAndUnderCenterOpacity: 0.3,
                    controller: FixedExtentScrollController(initialItem: selectedDay - 1),
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
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: isSelected ? 17 : 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? primary : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                      childCount: 31,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                            "Reset Default",
                            style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (selectedDay != 1) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await settingsProvider.setPeriodStartDay(selectedDay);
                          if (context.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
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
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context,
      {required String label, required int day, required int selected, required VoidCallback onTap}) {
    final isSelected = selected == day;
    final primary = Theme.of(context).primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primary : Colors.grey[200]!),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700])),
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Rentang Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: const Text('Pilih data yang ingin dimasukkan ke laporan PDF:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _PdfRange.all),
          child: const Text('Semua Data'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _PdfRange.custom),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Pilih Rentang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

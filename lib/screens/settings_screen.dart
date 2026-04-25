import 'package:flutter/material.dart';
import 'package:money_tracker/screens/montly_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'reminder_settings_screen.dart';
import '../providers/widget_provider.dart';
import '../utils/constants.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
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
              icon: Icons.notifications_active_rounded,
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
          ]),

          const SizedBox(height: 24),

          // 2. Section Widget
          _buildSectionHeader("Kustomisasi Widget"),
          _buildSettingsContainer([
            _buildSettingTile(
              context,
              icon: Icons.widgets_rounded,
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
              icon: Icons.upload_file_rounded,
              iconColor: Colors.green,
              title: 'Ekspor Data',
              subtitle: 'Backup ke JSON atau CSV',
              onTap: () => _showExportOptions(context, expenseProvider),
            ),
            const SizedBox(height: 4),
            _buildSettingTile(
              context,
              icon: Icons.download_rounded,
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
              icon: Icons.privacy_tip_rounded,
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
              icon: Icons.delete_forever_rounded,
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
                Text(
                  "Money Tracker v1.0.0",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  // --- WIDGET BUILDERS (Tetap Sama) ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
      // Tambahkan padding vertical agar item paling atas dan bawah tidak nempel ke pinggir container
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
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
        // Hapus border radius di sini agar inkwell memenuhi lebar container
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ), // Padding disesuaikan
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontWeight: FontWeight.w600,
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
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Bagian Logic _showExportOptions, _showImportOptions, dll TETAP SAMA seperti kode sebelumnya) ...
  // Silakan copy-paste method logic dari jawaban sebelumnya ke sini agar file lengkap.

  void _showExportOptions(BuildContext context, ExpenseProvider provider) {
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
                  Icons.data_object,
                  Colors.orange,
                  () {
                    Navigator.pop(ctx);
                    _exportToJson(context, provider);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionBtn(
                  ctx,
                  "Format CSV (Excel)",
                  Icons.table_chart,
                  Colors.green,
                  () {
                    Navigator.pop(ctx);
                    _exportToCsv(context, provider);
                  },
                ),
                const SizedBox(height: 24),
                _formatInfo(),
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
                  Icons.upload_file,
                  Colors.blue,
                  () {
                    Navigator.pop(ctx);
                    _importFromJson(context, provider);
                  },
                ),
                const SizedBox(height: 12),
                _buildActionBtn(
                  ctx,
                  "Dari File CSV",
                  Icons.grid_on,
                  Colors.teal,
                  () {
                    Navigator.pop(ctx);
                    _importFromCsv(context, provider);
                  },
                ),
                const SizedBox(height: 24),
                _formatInfo(),
              ],
            ),
          ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          // PERBAIKAN DISINI: Tambahkan horizontal: 20
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          alignment:
              Alignment
                  .centerLeft, // Ikon tetap rata kiri, tapi ada jarak 20px dari pinggir
        ),
      ),
    );
  }

  Widget _formatInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.blue),
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
                mainAxisSize: MainAxisSize.min, // Agar dialog fit dengan konten
                children: [
                  // 1. Ikon Peringatan Besar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Judul & Pesan
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
                      height: 1.5, // Spasi antar baris teks agar enak dibaca
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Tombol Aksi
                  Row(
                    children: [
                      // Tombol Batal
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16), // Jarak antar tombol
                      // Tombol Hapus (Merah)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx); // Tutup dialog dulu
                            await provider.clearAllExpenses(); // Proses hapus

                            // Tampilkan notifikasi sukses (opsional jika mau pakai dialog sukses yang ada)
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

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            content: Text(message),
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
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            content: Text(message),
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

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full height jika perlu
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            height:
                MediaQuery.of(context).size.height * 0.75, // Tinggi 75% layar
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const Text(
                  "Kebijakan Privasi",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Terakhir diperbarui: November 2025", // Sesuaikan tanggal
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Konten Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPolicyItem(
                          "1. Pengumpulan Data",
                          "Aplikasi Money Tracker menghormati privasi Anda. Kami tidak mengumpulkan, menyimpan, atau mengirimkan data pribadi atau finansial Anda ke server eksternal manapun.",
                        ),
                        _buildPolicyItem(
                          "2. Penyimpanan Lokal",
                          "Seluruh data transaksi, kategori, dan pengaturan disimpan secara lokal (offline) di dalam memori internal perangkat Anda menggunakan teknologi enkripsi standar database Hive.",
                        ),
                        _buildPolicyItem(
                          "3. Akses Internet",
                          "Aplikasi ini tidak memerlukan koneksi internet untuk fungsi utamanya (mencatat dan melihat laporan).",
                        ),
                        _buildPolicyItem(
                          "4. Keamanan Data",
                          "Karena data tersimpan di perangkat Anda, keamanan data bergantung pada keamanan fisik perangkat Anda (PIN, Pola, Sidik Jari). Kami menyarankan Anda untuk mengamankan HP Anda.",
                        ),
                        _buildPolicyItem(
                          "5. Izin Perangkat",
                          "Aplikasi mungkin meminta izin akses penyimpanan (Storage) HANYA ketika Anda melakukan fitur Ekspor/Impor data (CSV/JSON).",
                        ),
                        _buildPolicyItem(
                          "6. Penghapusan Data",
                          "Anda memiliki kendali penuh. Anda dapat menghapus seluruh data secara permanen melalui menu 'Hapus Semua Data' di halaman Pengaturan.",
                        ),

                        const SizedBox(height: 20),
                        // Tombol Tutup
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Tutup",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPolicyItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
              fontSize: 14,
            ),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pilih 3 kategori favorit untuk akses cepat",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 24),
                ...List.generate(3, (index) {
                  final category = provider.favoriteCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Constants.getCategoryStyle(category)['color'].withOpacity(0.1),
                        child: Icon(
                          Constants.getCategoryStyle(category)['icon'],
                          color: Constants.getCategoryStyle(category)['color'],
                          size: 20,
                        ),
                      ),
                      title: Text("Slot ${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      trailing: const Icon(Icons.edit_rounded, size: 20),
                      onTap: () => _showCategoryPicker(context, index, provider),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showCategoryPicker(BuildContext context, int slotIndex, WidgetProvider provider) {
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
            const Text("Pilih Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          child: Icon(style['icon'], color: style['color']),
                        ),
                        const SizedBox(height: 8),
                        Text(cat, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
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
}

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  // Export ke JSON
  static Future<String> exportToJson(List<Expense> expenses) async {
    try {
      // Request permission
      final status = await _requestStoragePermission();
      if (!status) {
        throw Exception('Izin akses penyimpanan diperlukan untuk ekspor data');
      }

      // Buat folder khusus
      final exportDir = await _getOrCreateExportDirectory();

      // Generate nama file yang proper
      final fileName = _generateFileName('json');
      final file = File('${exportDir.path}/$fileName');

      // Convert expenses to JSON
      final jsonData = expenses.map((expense) => expense.toMap()).toList();
      final jsonString = _formatJson(jsonData);

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Gagal mengekspor: $e');
    }
  }

  // Export ke CSV
  static Future<String> exportToCsv(List<Expense> expenses) async {
    try {
      final status = await _requestStoragePermission();
      if (!status) {
        throw Exception('Izin akses penyimpanan diperlukan untuk ekspor data');
      }

      final exportDir = await _getOrCreateExportDirectory();
      final fileName = _generateFileName('csv');
      final file = File('${exportDir.path}/$fileName');

      // Create CSV data
      final List<List<dynamic>> csvData = [
        ['ID', 'Judul', 'Jumlah', 'Tanggal', 'Kategori', 'Waktu'],
        ...expenses
            .map(
              (expense) => [
                expense.id,
                expense.title,
                expense.amount,
                DateFormat('yyyy-MM-dd').format(expense.date),
                expense.category,
                DateFormat('HH:mm:ss').format(expense.date),
              ],
            )
            .toList(),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);
      return file.path;
    } catch (e) {
      throw Exception('Gagal mengekspor: $e');
    }
  }

  static Future<Directory> _getOrCreateExportDirectory() async {
    // Path publik langsung di root storage
    const exportPath = "/storage/emulated/0/MoneyTracker Export";

    final exportDir = Directory(exportPath);

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  // Generate nama file yang descriptive
  static String _generateFileName(String extension) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = dateFormat.format(now);

    return 'pengeluaran_$timestamp.$extension';
  }

  // Format JSON agar rapi
  static String _formatJson(List<Map<String, dynamic>> jsonData) {
    final buffer = StringBuffer();
    buffer.write('[\n');

    for (int i = 0; i < jsonData.length; i++) {
      final expense = jsonData[i];
      buffer.write('  {\n');

      final keys = expense.keys.toList();
      for (int j = 0; j < keys.length; j++) {
        final key = keys[j];
        final value = expense[key];
        final isLast = j == keys.length - 1;

        if (value is DateTime) {
          buffer.write('    "$key": "${value.toIso8601String()}"');
        } else if (value is String) {
          buffer.write('    "$key": "$value"');
        } else {
          buffer.write('    "$key": $value');
        }

        buffer.write(isLast ? '\n' : ',\n');
      }

      buffer.write(i == jsonData.length - 1 ? '  }\n' : '  },\n');
    }

    buffer.write(']');
    return buffer.toString();
  }

  // Request storage permission
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;

        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else {
        // Untuk iOS, gunakan permission yang sesuai
        final status = await Permission.storage.status;
        if (status.isGranted) return true;

        final result = await Permission.storage.request();
        return result.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  // Method untuk mendapatkan semua file export
  static Future<List<File>> getExportFiles() async {
    try {
      final exportDir = await _getOrCreateExportDirectory();
      if (await exportDir.exists()) {
        final files = exportDir.listSync();
        return files.whereType<File>().toList()..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Method untuk menghapus file export lama (opsional)
  static Future<void> cleanupOldExports({int keepLast = 10}) async {
    try {
      final files = await getExportFiles();
      if (files.length > keepLast) {
        for (int i = keepLast; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {}
  }
}

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense.dart';

class ImportService {
  // Import dari JSON
  static Future<List<Expense>> importFromJson() async {
    try {
      // FilePicker akan menangani permission secara otomatis
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Tidak ada file yang dipilih');
      }

      final file = result.files.first;
      final content = String.fromCharCodes(file.bytes!);

      final expenses = <Expense>[];

      try {
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            expenses.add(Expense.fromMap(item));
          }
        }
      } catch (e) {
        throw Exception('Format file tidak valid: $e');
      }

      return expenses;
    } catch (e) {
      throw Exception('Gagal mengimpor: $e');
    }
  }

  // Import dari CSV
  static Future<List<Expense>> importFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Tidak ada file yang dipilih');
      }

      final file = result.files.first;
      final content = String.fromCharCodes(file.bytes!);

      try {
        final csvData = const CsvToListConverter().convert(content);
        final expenses = <Expense>[];

        for (int i = 1; i < csvData.length; i++) {
          final row = csvData[i];
          if (row.length >= 5) {
            final expense = Expense(
              id: row[0].toString(),
              title: row[1].toString(),
              amount: double.tryParse(row[2].toString()) ?? 0,
              date: DateTime.parse(row[3].toString()),
              category: row[4].toString(),
            );
            expenses.add(expense);
          }
        }

        return expenses;
      } catch (e) {
        throw Exception('Format CSV tidak valid: $e');
      }
    } catch (e) {
      throw Exception('Gagal mengimpor: $e');
    }
  }
}
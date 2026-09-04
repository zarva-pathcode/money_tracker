import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../main.dart';

class ReminderSetting {
  final int id;
  String label;
  bool isActive;
  TimeOfDay time;

  ReminderSetting({
    required this.id,
    required this.label,
    this.isActive = false,
    this.time = const TimeOfDay(hour: 9, minute: 0),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'isActive': isActive,
        'hour': time.hour,
        'minute': time.minute,
      };

  factory ReminderSetting.fromJson(Map<String, dynamic> json) {
    return ReminderSetting(
      id: json['id'] as int,
      label: json['label'] as String,
      isActive: json['isActive'] as bool? ?? false,
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 9,
        minute: json['minute'] as int? ?? 0,
      ),
    );
  }
}

class SettingsProvider with ChangeNotifier {
  final HiveService _hiveService;
  
  late List<ReminderSetting> reminders;

  SettingsProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadSettings();
  }

  void _loadSettings() {
    final rawJson = _hiveService.getSetting<dynamic>('reminders_list', null);
    if (rawJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawJson as String);
        reminders = decoded
            .map((item) => ReminderSetting.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      } catch (e) {
        debugPrint("Error loading reminders_list JSON: $e");
      }
    }

    // Check legacy migration
    final hasLegacyData = _hiveService.getSetting<dynamic>('rem_101_active', null) != null ||
        _hiveService.getSetting<dynamic>('rem_102_active', null) != null ||
        _hiveService.getSetting<dynamic>('rem_103_active', null) != null;

    if (hasLegacyData) {
      reminders = [
        _getLegacyReminder(101, 'Pagi', 9, 0),
        _getLegacyReminder(102, 'Siang', 13, 0),
        _getLegacyReminder(103, 'Malam', 20, 0),
      ];
      _saveReminders();

      // Cleanup legacy keys
      for (final id in [101, 102, 103]) {
        _hiveService.deleteSetting('rem_${id}_active');
        _hiveService.deleteSetting('rem_${id}_hour');
        _hiveService.deleteSetting('rem_${id}_minute');
      }
    } else {
      // Default 3 presets for new user
      reminders = [
        ReminderSetting(id: 101, label: 'Pagi', isActive: false, time: const TimeOfDay(hour: 9, minute: 0)),
        ReminderSetting(id: 102, label: 'Siang', isActive: false, time: const TimeOfDay(hour: 13, minute: 0)),
        ReminderSetting(id: 103, label: 'Malam', isActive: false, time: const TimeOfDay(hour: 20, minute: 0)),
      ];
      _saveReminders();
    }
  }

  ReminderSetting _getLegacyReminder(int id, String label, int defH, int defM) {
    final isActive = _hiveService.getSetting('rem_${id}_active', false);
    final hour = _hiveService.getSetting('rem_${id}_hour', defH);
    final minute = _hiveService.getSetting('rem_${id}_minute', defM);
    
    return ReminderSetting(
      id: id,
      label: label,
      isActive: isActive,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> _saveReminders() async {
    final encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await _hiveService.setSetting('reminders_list', encoded);
  }

  // --- Onboarding ---
  bool get isFirstTime => _hiveService.getSetting('hasSeenOnboarding', true);

  Future<void> setOnboardingSeen() async {
    await _hiveService.setSetting('hasSeenOnboarding', false);
  }

  // --- Hide Amount ---
  bool get hideAmount => _hiveService.getSetting('hide_amount', false);

  Future<void> setHideAmount(bool value) async {
    await _hiveService.setSetting('hide_amount', value);
    notifyListeners();
  }

  // --- Budget Alerts ---
  bool get budgetAlertsEnabled => _hiveService.getSetting('budget_alerts_enabled', true);

  Future<void> setBudgetAlertsEnabled(bool value) async {
    await _hiveService.setSetting('budget_alerts_enabled', value);
    notifyListeners();
  }

  // --- Period Start Day ---
  int get periodStartDay => _hiveService.getSetting('period_start_day', 1);

  Future<void> setPeriodStartDay(int day) async {
    await _hiveService.setSetting('period_start_day', day.clamp(1, 31));
    notifyListeners();
  }

  Future<void> addReminder(String label, TimeOfDay time) async {
    int maxId = 103;
    for (final r in reminders) {
      if (r.id > maxId) maxId = r.id;
    }
    final newId = maxId + 1;

    final newRem = ReminderSetting(
      id: newId,
      label: label.trim(),
      isActive: true,
      time: time,
    );

    reminders.add(newRem);
    notifyListeners();
    await _saveReminders();

    final hasPerm = await NotificationService.requestAndCheckPermission();
    if (!hasPerm) {
      _showSnackBar('Izin notifikasi belum diberikan. Pengingat dibuat tanpa notifikasi aktif.');
      return;
    }

    final exactAlarmGranted = await NotificationService.requestExactAlarmPermission();
    if (!exactAlarmGranted && Platform.isAndroid) {
      _showSnackBar('Izin Alarm Eksak ditolak. Notifikasi mungkin telat muncul karena mode hemat baterai Android 14+.');
    }

    final result = await NotificationService.scheduleDaily(
      id: newId,
      title: 'Ingat Catat Pengeluaran!',
      body: 'Yuk, catat transaksi kamu sekarang agar tetap terkontrol.',
      time: time,
    );

    if (!result.isSuccess) {
      _showSnackBar(result.message);
    } else {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      _showSnackBar('Notifikasi ${newRem.label} aktif — akan muncul setiap jam $h:$m');
    }
  }

  Future<void> deleteReminder(int id) async {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final deleted = reminders.removeAt(index);
    notifyListeners();
    await _saveReminders();

    await NotificationService.cancelReminder(id);
    _showSnackBar('Pengingat "${deleted.label}" berhasil dihapus');
  }

  Future<void> updateReminder(int id, bool isActive, TimeOfDay newTime, {String? newLabel}) async {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    // Optimistic UI
    reminders[index].isActive = isActive;
    reminders[index].time = newTime;
    if (newLabel != null && newLabel.trim().isNotEmpty) {
      reminders[index].label = newLabel.trim();
    }
    notifyListeners();

    // Persist full list to Hive
    await _saveReminders();

    // Update notification
    if (isActive) {
      final hasPerm = await NotificationService.requestAndCheckPermission();
      if (!hasPerm) {
        _showSnackBar('Izin notifikasi belum diberikan. Buka Pengaturan > Notifikasi > Money Tracker untuk mengaktifkan.');
        return;
      }
      
      final exactAlarmGranted = await NotificationService.requestExactAlarmPermission();
      if (!exactAlarmGranted && Platform.isAndroid) {
        _showSnackBar('Izin Alarm Eksak ditolak. Notifikasi mungkin telat muncul karena mode hemat baterai Android 14+.');
      }

      final result = await NotificationService.scheduleDaily(
        id: id,
        title: 'Ingat Catat Pengeluaran!',
        body: 'Yuk, catat transaksi kamu sekarang agar tetap terkontrol.',
        time: newTime,
      );

      if (!result.isSuccess) {
        _showSnackBar(result.message);
      } else {
        final label = reminders[index].label;
        final h = newTime.hour.toString().padLeft(2, '0');
        final m = newTime.minute.toString().padLeft(2, '0');
        _showSnackBar('Notifikasi $label aktif — akan muncul setiap jam $h:$m');
      }
    } else {
    await NotificationService.cancelReminder(id);
      final label = reminders[index].label;
      _showSnackBar('Notifikasi $label dinonaktifkan');
    }
  }

  void _showSnackBar(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> rescheduleAll() async {
    final hasPerm = await NotificationService.hasPermission();
    if (!hasPerm) return;

    // Batalkan semua reminder notifikasi (ID 100-199) saja
    // JANGAN pakai cancelAll() karena itu akan membatalkan budget alerts juga
    for (final rem in reminders) {
      await NotificationService.cancelReminder(rem.id);
    }

    // Delay singkat untuk memastikan cancellation selesai
    await Future.delayed(const Duration(milliseconds: 100));

    // Jadwalkan ulang hanya yang aktif
    for (final rem in reminders) {
      if (rem.isActive) {
        await NotificationService.scheduleDaily(
          id: rem.id,
          title: 'Ingat Catat Pengeluaran!',
          body: 'Yuk, catat transaksi kamu sekarang agar tetap terkontrol.',
          time: rem.time,
        );
      }
    }
  }
}

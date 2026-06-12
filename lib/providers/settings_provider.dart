import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../main.dart';

class ReminderSetting {
  final int id;
  final String label;
  bool isActive;
  TimeOfDay time;

  ReminderSetting({
    required this.id,
    required this.label,
    this.isActive = false,
    this.time = const TimeOfDay(hour: 9, minute: 0),
  });
}

class SettingsProvider with ChangeNotifier {
  final HiveService _hiveService;
  
  late List<ReminderSetting> reminders;

  SettingsProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadSettings();
  }

  void _loadSettings() {
    reminders = [
      _getReminder(101, 'Pagi', 9, 0),
      _getReminder(102, 'Siang', 13, 0),
      _getReminder(103, 'Malam', 20, 0),
    ];
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

  ReminderSetting _getReminder(int id, String label, int defH, int defM) {
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

  Future<void> updateReminder(int id, bool isActive, TimeOfDay newTime) async {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    // Optimistic UI
    reminders[index].isActive = isActive;
    reminders[index].time = newTime;
    notifyListeners();

    // Always persist to Hive (tidak di-rollback)
    await _hiveService.setSetting('rem_${id}_active', isActive);
    await _hiveService.setSetting('rem_${id}_hour', newTime.hour);
    await _hiveService.setSetting('rem_${id}_minute', newTime.minute);

    // Update notification (bisa gagal independen)
    if (isActive) {
      final hasPerm = await NotificationService.requestAndCheckPermission();
      if (!hasPerm) {
        _showSnackBar('Izin notifikasi belum diberikan. Buka Pengaturan > Notifikasi > Money Tracker untuk mengaktifkan.');
        return;
      }

      final result = await NotificationService.scheduleDaily(
        id: id,
        title: 'Ingat Catat Pengeluaran!',
        body: 'Yuk, catat transaksi kamu sekarang agar tetap terkontrol.',
        time: newTime,
      );

      if (!result.isSuccess) {
        _showSnackBar(result.message);
      }
    } else {
      await NotificationService.cancel(id);
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

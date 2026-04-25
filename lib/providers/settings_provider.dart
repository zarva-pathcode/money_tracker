import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/notification_service.dart';

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
  final Box _box = Hive.box('settings');
  
  late List<ReminderSetting> reminders;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    reminders = [
      _getReminder(101, 'Pagi', 9, 0),
      _getReminder(102, 'Siang', 13, 0),
      _getReminder(103, 'Malam', 20, 0),
    ];
  }

  ReminderSetting _getReminder(int id, String label, int defH, int defM) {
    final isActive = _box.get('rem_${id}_active', defaultValue: false);
    final hour = _box.get('rem_${id}_hour', defaultValue: defH);
    final minute = _box.get('rem_${id}_minute', defaultValue: defM);
    
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

    reminders[index].isActive = isActive;
    reminders[index].time = newTime;

    // Save to Hive
    await _box.put('rem_${id}_active', isActive);
    await _box.put('rem_${id}_hour', newTime.hour);
    await _box.put('rem_${id}_minute', newTime.minute);

    // Update Notification
    if (isActive) {
      await NotificationService.scheduleDaily(
        id: id,
        title: 'Ingat Catat Pengeluaran!',
        body: 'Yuk, catat transaksi kamu sekarang agar tetap terkontrol.',
        time: newTime,
      );
    } else {
      await NotificationService.cancel(id);
    }

    notifyListeners();
  }
}

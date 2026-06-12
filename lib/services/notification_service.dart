import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationScheduleResult {
  success,
  permissionDenied,
  exactAlarmDenied,
  error;

  bool get isSuccess => this == success;

  String get message {
    switch (this) {
      case NotificationScheduleResult.success:
        return 'Notifikasi berhasil dijadwalkan';
      case NotificationScheduleResult.permissionDenied:
        return 'Izin notifikasi belum diberikan';
      case NotificationScheduleResult.exactAlarmDenied:
        return 'Izin alarm eksak belum diberikan. Notifikasi akan dikirim perkiraan waktu.';
      case NotificationScheduleResult.error:
        return 'Gagal menjadwalkan notifikasi. Coba restart HP.';
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    final androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notificationsPlugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _createChannels();
  }

  static Future<void> _createChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'daily_reminder_channel',
        'Pengeluaran Harian',
        description: 'Pengingat untuk mencatat transaksi harian',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        'budget_alerts_channel',
        'Peringatan Anggaran',
        description: 'Notifikasi ketika pengeluaran mendekati atau melebihi anggaran',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;
      await androidPlugin.requestNotificationsPermission();
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin == null) return false;
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
    return true;
  }

  static Future<bool> requestAndCheckPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;
      final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
      if (!enabled) {
        await androidPlugin.requestNotificationsPermission();
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
      return true;
    }
    return true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return false;
    final result = await androidPlugin.requestExactAlarmsPermission();
    return result ?? false;
  }

  static Future<NotificationScheduleResult> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (Platform.isAndroid) {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder_channel',
              'Pengeluaran Harian',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      return NotificationScheduleResult.success;
    } catch (e) {
      debugPrint("NotificationService.scheduleDaily error: $e");
      return NotificationScheduleResult.error;
    }
  }

  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts_channel',
            'Peringatan Anggaran',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("NotificationService.showBudgetAlert error: $e");
    }
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}

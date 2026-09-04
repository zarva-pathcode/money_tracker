import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  /// ID prefix untuk membedakan reminder notifications dari budget alerts
  /// Reminder: ID 100-199, Budget alerts: ID 200+
  static const int _reminderIdBase = 100;
  static const int _budgetAlertIdBase = 200;

  /// Mapping timezone abbreviation (non-IANA) ke IANA timezone name
  static const Map<String, String> _timezoneAliases = {
    'WIB': 'Asia/Jakarta',
    'wib': 'Asia/Jakarta',
    'WITA': 'Asia/Makassar',
    'wita': 'Asia/Makassar',
    'WIT': 'Asia/Jayapura',
    'wit': 'Asia/Jayapura',
    'JST': 'Asia/Tokyo',
    'KST': 'Asia/Seoul',
    'HKT': 'Asia/Hong_Kong',
    'SGT': 'Asia/Singapore',
    'IST': 'Asia/Kolkata',
    'GMT': 'UTC',
    'UTC': 'UTC',
  };

  /// Inisialisasi timezone dan notification plugin
  static Future<void> init() async {
    tz.initializeTimeZones();

    bool timezoneSet = false;

    // Coba dapatkan timezone dari device
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;

      debugPrint('[NOTIF] Raw timezone identifier: "$timeZoneName"');
      debugPrint('[NOTIF] Is valid IANA: ${tz.timeZoneDatabase.locations.containsKey(timeZoneName)}');

      if (_isValidIANATimezone(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        timezoneSet = true;
        debugPrint('[NOTIF] ✅ Timezone set to: $timeZoneName');
      } else {
        final mapped = _timezoneAliases[timeZoneName];
        if (mapped != null && _isValidIANATimezone(mapped)) {
          tz.setLocalLocation(tz.getLocation(mapped));
          timezoneSet = true;
          debugPrint('[NOTIF] ✅ Timezone mapped from "$timeZoneName" to: $mapped');
        } else {
          debugPrint('[NOTIF] ⚠️ Identifier "$timeZoneName" not in IANA database');
        }
      }
    } catch (e) {
      debugPrint('[NOTIF] ⚠️ FlutterTimezone.getLocalTimezone() failed: $e');
    }

    // Fallback: gunakan DateTime.now().timeZoneName
    if (!timezoneSet) {
      timezoneSet = _fallbackToSystemTimezone();
    }

    // Last resort: offset-based
    if (!timezoneSet) {
      timezoneSet = _fallbackToOffset();
    }

    if (!timezoneSet) {
      debugPrint('[NOTIF] ❌ CRITICAL: Semua fallback timezone gagal! Notifications akan salah waktu.');
    }

    debugPrint('[NOTIF] Final tz.local: ${tz.local.name}');

    // Inisialisasi plugin
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

    // Verifikasi: cek pending notifications
    await _debugPrintPending();
  }

  // ==========================================================================
  // TIMEZONE HELPERS
  // ==========================================================================

  static bool _isValidIANATimezone(String? name) {
    if (name == null || name.isEmpty) return false;
    return tz.timeZoneDatabase.locations.containsKey(name);
  }

  /// Fallback: map DateTime.now().timeZoneName ke IANA
  static bool _fallbackToSystemTimezone() {
    try {
      final systemTz = DateTime.now().timeZoneName;
      debugPrint('[NOTIF] System timezone name: "$systemTz"');

      final mapped = _timezoneAliases[systemTz];
      if (mapped != null && _isValidIANATimezone(mapped)) {
        tz.setLocalLocation(tz.getLocation(mapped));
        debugPrint('[NOTIF] ✅ Fallback (system) → $mapped');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NOTIF] ⚠️ Fallback system failed: $e');
      return false;
    }
  }

  /// Last resort: gunakan offset hours dari DateTime.now()
  static bool _fallbackToOffset() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      // IANA Etc/GMT uses INVERTED sign: Etc/GMT-7 = UTC+7
      final locationName = 'Etc/GMT${hours >= 0 ? '-' : '+'}${hours.abs()}';

      if (_isValidIANATimezone(locationName)) {
        tz.setLocalLocation(tz.getLocation(locationName));
        debugPrint('[NOTIF] ✅ Fallback (offset) → $locationName (UTC${hours >= 0 ? '+' : ''}$hours)');
        return true;
      }
      debugPrint('[NOTIF] ⚠️ Offset fallback "$locationName" not valid');
      return false;
    } catch (e) {
      debugPrint('[NOTIF] ⚠️ Fallback offset failed: $e');
      return false;
    }
  }

  // ==========================================================================
  // NOTIFICATION CHANNELS
  // ==========================================================================

  static Future<void> _createChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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

  // ==========================================================================
  // PERMISSION MANAGEMENT
  // ==========================================================================

  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.areNotificationsEnabled() ?? false;
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return false;
      await androidPlugin.requestNotificationsPermission();
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin == null) return false;
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
    return true;
  }

  static Future<bool> requestAndCheckPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
    if (!enabled) {
      await androidPlugin.requestNotificationsPermission();
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final result = await androidPlugin.requestExactAlarmsPermission();
    return result ?? false;
  }

  // ==========================================================================
  // SCHEDULE DAILY REMINDER
  // ==========================================================================

  static Future<NotificationScheduleResult> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    // Gunakan ID unik untuk reminder (base 100 + id)
    final notifId = _reminderIdBase + id;

    try {
      final now = tz.TZDateTime.now(tz.local);
      debugPrint('[NOTIF] === scheduleDaily ID=$notifId ===');
      debugPrint('[NOTIF] Device now: ${DateTime.now()}');
      debugPrint('[NOTIF] TZDateTime.now(): $now (tz: ${tz.local.name})');
      debugPrint('[NOTIF] Target time: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Jika waktu sudah lewat hari ini, jadwalkan besok
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final diff = scheduledDate.difference(now);
      debugPrint('[NOTIF] scheduledDate: $scheduledDate');
      debugPrint('[NOTIF] UTC equivalent: ${scheduledDate.toUtc()}');
      debugPrint('[NOTIF] Difference from now: ${diff.inHours}h ${diff.inMinutes % 60}m');

      // Cancel notifikasi lama dengan ID yang sama
      await _notificationsPlugin.cancel(id: notifId);

      // Coba schedule dengan exact mode
      bool scheduled = false;

      if (Platform.isAndroid) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: notifId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_reminder_channel',
                'Pengeluaran Harian',
                importance: Importance.max,
                priority: Priority.high,
                ongoing: false,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          scheduled = true;
          debugPrint('[NOTIF] ✅ Scheduled with exactAllowWhileIdle');
        } catch (e) {
          debugPrint('[NOTIF] ⚠️ exactAllowWhileIdle failed: $e');
          // Fallback ke inexact
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notifId,
              title: title,
              body: body,
              scheduledDate: scheduledDate,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'daily_reminder_channel',
                  'Pengeluaran Harian',
                  importance: Importance.max,
                  priority: Priority.high,
                  ongoing: false,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            scheduled = true;
            debugPrint('[NOTIF] ✅ Scheduled with inexactAllowWhileIdle (fallback)');
          } catch (e2) {
            debugPrint('[NOTIF] ❌ inexactAllowWhileIdle juga gagal: $e2');
          }
        }
      } else {
        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduled = true;
        debugPrint('[NOTIF] ✅ Scheduled (iOS)');
      }

      if (!scheduled) {
        return NotificationScheduleResult.error;
      }

      // VERIFIKASI: cek apakah benar-benar masuk pending
      await _debugPrintPending();

      return NotificationScheduleResult.success;
    } catch (e) {
      debugPrint('[NOTIF] ❌ scheduleDaily error: $e');
      return NotificationScheduleResult.error;
    }
  }

  // ==========================================================================
  // BUDGET ALERTS (instan, tidak scheduled)
  // ==========================================================================

  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      // Budget alerts menggunakan ID base 200 + index
      final notifId = _budgetAlertIdBase + id;
      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
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
      debugPrint('[NOTIF] Budget alert shown: ID=$notifId');
    } catch (e) {
      debugPrint('[NOTIF] showBudgetAlert error: $e');
    }
  }

  // ==========================================================================
  // CANCEL METHODS
  // ==========================================================================

  /// Cancel reminder notifikasi saja (ID 100-199)
  /// TIDAK membatalkan budget alerts (ID 200+)
  static Future<void> cancelReminder(int id) async {
    final notifId = _reminderIdBase + id;
    await _notificationsPlugin.cancel(id: notifId);
    debugPrint('[NOTIF] Cancelled reminder ID=$notifId');
  }

  /// Cancel SEMUA notifikasi (termasuk budget alerts)
  /// Hanya gunakan saat reset total
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[NOTIF] All notifications cancelled');
  }

  // ==========================================================================
  // DEBUG & VERIFICATION
  // ==========================================================================

  static Future<void> showTestNotification() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
          debugPrint('[NOTIF] Notification enabled: $enabled');
        }
      }

      await _notificationsPlugin.show(
        id: 999,
        title: '🔔 Test Notifikasi',
        body: 'Jika kamu melihat ini, notifikasi BERFUNGSI dengan baik!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Pengeluaran Harian',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('[NOTIF] ✅ Test notification shown');
    } catch (e) {
      debugPrint('[NOTIF] ❌ Test notification error: $e');
    }
  }

  static Future<void> _debugPrintPending() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('[NOTIF] === Pending notifications: ${pending.length} ===');
      for (final n in pending) {
        debugPrint('[NOTIF]   ID=${n.id}, title="${n.title}", body="${n.body}"');
      }
      debugPrint('[NOTIF] === End pending ===');
    } catch (e) {
      debugPrint('[NOTIF] pendingNotificationRequests error: $e');
    }
  }

  /// Debug: print semua pending notifications
  static Future<void> printPendingNotifications() async {
    await _debugPrintPending();
  }
}

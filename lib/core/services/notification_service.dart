import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to interview/diary screen
    // This will be connected to the router via a callback
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundFile,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: soundFile != null
          ? RawResourceAndroidNotificationSound(soundFile)
          : null,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: soundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDiaryReminder({
    required int id,
    required DateTime time,
  }) async {
    await scheduleAlarm(
      id: id,
      title: 'Time to reflect',
      body: 'How was your day? Let\'s chat about it before sleep.',
      scheduledTime: time,
    );
  }

  Future<void> scheduleMealReminder({
    required int id,
    required DateTime time,
  }) async {
    await scheduleAlarm(
      id: id,
      title: 'Meal check-in',
      body: 'What did you eat? Snap a photo of your meal!',
      scheduledTime: time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

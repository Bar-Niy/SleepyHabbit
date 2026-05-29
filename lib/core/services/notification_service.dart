import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Notification service using INEXACT alarms for Google Play compliance.
///
/// IMPORTANT: We intentionally use AndroidScheduleMode.inexactAllowWhileIdle
/// instead of exact alarms. Here's why:
///
/// 1. Google Play REJECTS apps using SCHEDULE_EXACT_ALARM unless the app's
///    PRIMARY purpose is an alarm clock. SleepyHabbit is a sleep *tracker*
///    with alarm functionality, not a dedicated alarm clock.
///
/// 2. Inexact alarms have ±5 minutes of variance, which is perfectly
///    acceptable for:
///    - Wake-up alarms (±5 min is fine for a sleep improvement app)
///    - Diary reminders (timing is approximate by nature)
///    - Meal check-in nudges
///
/// 3. On Android 12+, inexact alarms still fire within a reasonable window
///    and don't require the dangerous SCHEDULE_EXACT_ALARM permission.
///
/// If users need EXACT alarm timing, they should use their phone's built-in
/// Clock app alongside SleepyHabbit. Our alarms serve as a trigger for the
/// morning interview flow, not as a precision timing device.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Notification channel IDs
  static const String _alarmChannelId = 'alarm_channel';
  static const String _reminderChannelId = 'reminder_channel';
  static const String _nudgeChannelId = 'nudge_channel';

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

    // Create notification channels with appropriate importance levels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // High-importance channel for wake-up alarms
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _alarmChannelId,
        'Wake-up Alarms',
        description: 'Morning alarm to trigger sleep interview',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    // Default-importance channel for diary/meal reminders
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Reminders',
        description: 'Diary and meal logging reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // Low-importance channel for nudges/insights
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _nudgeChannelId,
        'Insights & Tips',
        description: 'Sleep insights and proactive suggestions',
        importance: Importance.low,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to interview/diary screen
    // The payload contains the route to navigate to
    // This will be connected to the router via a global key or callback
  }

  /// Schedule a wake-up alarm.
  ///
  /// Uses INEXACT scheduling (±5 min window) which is compliant with
  /// Google Play policies. For a sleep improvement app, this variance
  /// is acceptable — the alarm triggers the morning interview flow.
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundFile,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      'Wake-up Alarms',
      channelDescription: 'Morning alarm to trigger sleep interview',
      importance: Importance.max,
      priority: Priority.high,
      sound: soundFile != null
          ? RawResourceAndroidNotificationSound(soundFile)
          : null,
      // NOTE: fullScreenIntent removed — requires special Google Play approval
      // since Android 14. Instead, use heads-up notification (Priority.high).
      fullScreenIntent: false,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // Show on lock screen
      styleInformation: BigTextStyleInformation(body),
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
      // CRITICAL: Use INEXACT alarms for Google Play compliance.
      // This avoids the need for SCHEDULE_EXACT_ALARM permission which
      // Google rejects for non-primary-alarm-clock apps.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/interview', // Route to open on tap
    );
  }

  /// Schedule an evening diary reminder.
  /// Uses the reminder channel (default importance, no fullscreen).
  Future<void> scheduleDiaryReminder({
    required int id,
    required DateTime time,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Reminders',
      channelDescription: 'Diary and meal logging reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      'Time to reflect',
      'How was your day? Let\'s chat about it before sleep.',
      tz.TZDateTime.from(time, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/diary',
    );
  }

  /// Schedule a meal photo reminder.
  Future<void> scheduleMealReminder({
    required int id,
    required DateTime time,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Reminders',
      channelDescription: 'Diary and meal logging reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      'Meal check-in',
      'What did you eat? Snap a photo of your meal!',
      tz.TZDateTime.from(time, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/meals/capture',
    );
  }

  /// Show an immediate nudge notification (for proactive suggestions).
  Future<void> showNudge({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _nudgeChannelId,
      'Insights & Tips',
      channelDescription: 'Sleep insights and proactive suggestions',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.recommendation,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

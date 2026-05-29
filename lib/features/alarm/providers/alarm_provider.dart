import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/notification_service.dart';

class AlarmsNotifier extends AsyncNotifier<List<Alarm>> {
  late final AppDatabase _db;

  @override
  Future<List<Alarm>> build() async {
    _db = DatabaseService.instance.database;
    return _db.alarmDao.getAllAlarms();
  }

  Future<void> addAlarm({
    required String label,
    required int hour,
    required int minute,
    required String daysOfWeek,
    int snoozeDuration = 5,
    int maxSnoozes = 3,
    bool vibrate = true,
  }) async {
    final id = await _db.alarmDao.insertAlarm(
      AlarmsCompanion(
        label: Value(label),
        hour: Value(hour),
        minute: Value(minute),
        daysOfWeek: Value(daysOfWeek),
        snoozeDuration: Value(snoozeDuration),
        maxSnoozes: Value(maxSnoozes),
        vibrate: Value(vibrate),
      ),
    );

    // Schedule the notification
    await _scheduleAlarmNotification(id, hour, minute, label);

    ref.invalidateSelf();
  }

  Future<void> toggleAlarm(int id, bool enabled) async {
    await _db.alarmDao.toggleAlarm(id, enabled);
    
    if (!enabled) {
      await NotificationService.instance.cancelNotification(id);
    } else {
      final alarm = await _db.alarmDao.getAlarmById(id);
      await _scheduleAlarmNotification(id, alarm.hour, alarm.minute, alarm.label);
    }

    ref.invalidateSelf();
  }

  Future<void> deleteAlarm(int id) async {
    await _db.alarmDao.deleteAlarmById(id);
    await NotificationService.instance.cancelNotification(id);
    ref.invalidateSelf();
  }

  Future<void> _scheduleAlarmNotification(
      int id, int hour, int minute, String label) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await NotificationService.instance.scheduleAlarm(
      id: id,
      title: 'Wake Up!',
      body: label,
      scheduledTime: scheduled,
    );
  }
}

final alarmsProvider = AsyncNotifierProvider<AlarmsNotifier, List<Alarm>>(() {
  return AlarmsNotifier();
});

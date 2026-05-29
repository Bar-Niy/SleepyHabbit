import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'alarm_dao.g.dart';

@DriftAccessor(tables: [Alarms])
class AlarmDao extends DatabaseAccessor<AppDatabase> with _$AlarmDaoMixin {
  AlarmDao(super.db);

  Future<List<Alarm>> getAllAlarms() => select(alarms).get();

  Stream<List<Alarm>> watchAllAlarms() => select(alarms).watch();

  Stream<List<Alarm>> watchEnabledAlarms() {
    return (select(alarms)..where((a) => a.isEnabled.equals(true))).watch();
  }

  Future<Alarm> getAlarmById(int id) {
    return (select(alarms)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<int> insertAlarm(AlarmsCompanion alarm) {
    return into(alarms).insert(alarm);
  }

  Future<bool> updateAlarm(Alarm alarm) {
    return update(alarms).replace(alarm);
  }

  Future<int> deleteAlarmById(int id) {
    return (delete(alarms)..where((a) => a.id.equals(id))).go();
  }

  Future<void> toggleAlarm(int id, bool enabled) {
    return (update(alarms)..where((a) => a.id.equals(id)))
        .write(AlarmsCompanion(isEnabled: Value(enabled)));
  }
}

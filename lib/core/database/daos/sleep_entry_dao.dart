import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'sleep_entry_dao.g.dart';

@DriftAccessor(tables: [SleepEntries])
class SleepEntryDao extends DatabaseAccessor<AppDatabase>
    with _$SleepEntryDaoMixin {
  SleepEntryDao(super.db);

  Future<List<SleepEntry>> getAllEntries() => select(sleepEntries).get();

  Stream<List<SleepEntry>> watchRecentEntries({int limit = 30}) {
    return (select(sleepEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  Future<SleepEntry?> getEntryForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(sleepEntries)
          ..where(
              (e) => e.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
  }

  Future<int> insertEntry(SleepEntriesCompanion entry) {
    return into(sleepEntries).insert(entry);
  }

  Future<bool> updateEntry(SleepEntry entry) {
    return update(sleepEntries).replace(entry);
  }

  Future<List<SleepEntry>> getEntriesInRange(DateTime start, DateTime end) {
    return (select(sleepEntries)
          ..where((e) => e.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<double?> getAverageQuality({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final entries = await (select(sleepEntries)
          ..where((e) => e.date.isBiggerThanValue(since))
          ..where((e) => e.qualityRating.isNotNull()))
        .get();
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + (e.qualityRating ?? 0));
    return total / entries.length;
  }
}

import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'diary_entry_dao.g.dart';

@DriftAccessor(tables: [DiaryEntries])
class DiaryEntryDao extends DatabaseAccessor<AppDatabase>
    with _$DiaryEntryDaoMixin {
  DiaryEntryDao(super.db);

  Future<List<DiaryEntry>> getAllEntries() => select(diaryEntries).get();

  Stream<List<DiaryEntry>> watchRecentEntries({int limit = 30}) {
    return (select(diaryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  Future<DiaryEntry?> getEntryForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(diaryEntries)
          ..where(
              (e) => e.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
  }

  Future<int> insertEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insert(entry);
  }

  Future<bool> updateEntry(DiaryEntry entry) {
    return update(diaryEntries).replace(entry);
  }
}

import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'nudge_dao.g.dart';

@DriftAccessor(tables: [Nudges])
class NudgeDao extends DatabaseAccessor<AppDatabase> with _$NudgeDaoMixin {
  NudgeDao(super.db);

  Future<List<Nudge>> getUnshownNudges() {
    return (select(nudges)
          ..where((n) => n.shown.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  Future<List<Nudge>> getTodaysNudges() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(nudges)
          ..where((n) => n.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  Future<int> insertNudge(NudgesCompanion nudge) {
    return into(nudges).insert(nudge);
  }

  Future<void> markShown(int id) {
    return (update(nudges)..where((n) => n.id.equals(id)))
        .write(const NudgesCompanion(shown: Value(true)));
  }

  Future<void> markDismissed(int id) {
    return (update(nudges)..where((n) => n.id.equals(id)))
        .write(const NudgesCompanion(dismissed: Value(true)));
  }

  Stream<List<Nudge>> watchActiveNudges() {
    return (select(nudges)
          ..where((n) => n.dismissed.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(5))
        .watch();
  }
}

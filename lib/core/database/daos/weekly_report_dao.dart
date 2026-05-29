import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'weekly_report_dao.g.dart';

@DriftAccessor(tables: [WeeklyReports])
class WeeklyReportDao extends DatabaseAccessor<AppDatabase>
    with _$WeeklyReportDaoMixin {
  WeeklyReportDao(super.db);

  Future<List<WeeklyReport>> getAllReports() =>
      (select(weeklyReports)
            ..orderBy([(r) => OrderingTerm.desc(r.weekStart)]))
          .get();

  Future<WeeklyReport?> getReportForWeek(DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 1));
    return (select(weeklyReports)
          ..where((r) => r.weekStart.isBetweenValues(start, end)))
        .getSingleOrNull();
  }

  Future<WeeklyReport?> getLatestReport() {
    return (select(weeklyReports)
          ..orderBy([(r) => OrderingTerm.desc(r.weekStart)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertReport(WeeklyReportsCompanion report) {
    return into(weeklyReports).insert(report);
  }

  Future<bool> updateReport(WeeklyReport report) {
    return update(weeklyReports).replace(report);
  }

  Stream<List<WeeklyReport>> watchReports({int limit = 8}) {
    return (select(weeklyReports)
          ..orderBy([(r) => OrderingTerm.desc(r.weekStart)])
          ..limit(limit))
        .watch();
  }
}

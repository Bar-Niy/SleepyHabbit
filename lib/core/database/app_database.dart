import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sleepy_habbit/core/database/tables.dart';
import 'package:sleepy_habbit/core/database/daos/alarm_dao.dart';
import 'package:sleepy_habbit/core/database/daos/sleep_entry_dao.dart';
import 'package:sleepy_habbit/core/database/daos/diary_entry_dao.dart';
import 'package:sleepy_habbit/core/database/daos/meal_entry_dao.dart';
import 'package:sleepy_habbit/core/database/daos/nightly_features_dao.dart';
import 'package:sleepy_habbit/core/database/daos/weekly_report_dao.dart';
import 'package:sleepy_habbit/core/database/daos/nudge_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Alarms,
    SleepEntries,
    DiaryEntries,
    MealEntries,
    ConversationMessages,
    NightlyFeatures,
    WeeklyReports,
    Nudges,
  ],
  daos: [
    AlarmDao,
    SleepEntryDao,
    DiaryEntryDao,
    MealEntryDao,
    NightlyFeaturesDao,
    WeeklyReportDao,
    NudgeDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(nightlyFeatures);
            await m.createTable(weeklyReports);
            await m.createTable(nudges);
            // Add extractedData column to MealEntries
            await m.addColumn(mealEntries, mealEntries.extractedData);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'sleepy_habbit.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  /// Export the database file for backup
  Future<File> getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'sleepy_habbit.db'));
  }
}

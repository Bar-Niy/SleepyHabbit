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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Alarms, SleepEntries, DiaryEntries, MealEntries, ConversationMessages],
  daos: [AlarmDao, SleepEntryDao, DiaryEntryDao, MealEntryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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

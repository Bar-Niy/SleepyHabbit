import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'meal_entry_dao.g.dart';

@DriftAccessor(tables: [MealEntries])
class MealEntryDao extends DatabaseAccessor<AppDatabase>
    with _$MealEntryDaoMixin {
  MealEntryDao(super.db);

  Future<List<MealEntry>> getAllEntries() => select(mealEntries).get();

  Stream<List<MealEntry>> watchTodaysMeals() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(mealEntries)
          ..where((e) => e.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<int> insertEntry(MealEntriesCompanion entry) {
    return into(mealEntries).insert(entry);
  }

  Future<bool> updateEntry(MealEntry entry) {
    return update(mealEntries).replace(entry);
  }

  Future<List<MealEntry>> getMealsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(mealEntries)
          ..where((e) => e.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }
}

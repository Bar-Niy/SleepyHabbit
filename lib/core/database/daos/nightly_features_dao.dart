import 'package:drift/drift.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

part 'nightly_features_dao.g.dart';

@DriftAccessor(tables: [NightlyFeatures])
class NightlyFeaturesDao extends DatabaseAccessor<AppDatabase>
    with _$NightlyFeaturesDaoMixin {
  NightlyFeaturesDao(super.db);

  Future<List<NightlyFeature>> getAllFeatures() =>
      select(nightlyFeatures).get();

  Future<List<NightlyFeature>> getRecentFeatures({int limit = 30}) {
    return (select(nightlyFeatures)
          ..orderBy([(f) => OrderingTerm.desc(f.date)])
          ..limit(limit))
        .get();
  }

  Future<List<NightlyFeature>> getFeaturesInRange(
      DateTime start, DateTime end) {
    return (select(nightlyFeatures)
          ..where((f) => f.date.isBetweenValues(start, end))
          ..orderBy([(f) => OrderingTerm.asc(f.date)]))
        .get();
  }

  Future<NightlyFeature?> getFeatureForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(nightlyFeatures)
          ..where((f) => f.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
  }

  Future<double?> getAverageQuality({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final entries = await (select(nightlyFeatures)
          ..where((f) => f.date.isBiggerThanValue(since))
          ..where((f) => f.sleepQuality.isNotNull()))
        .get();
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + e.sleepQuality!);
    return total / entries.length;
  }

  Stream<List<NightlyFeature>> watchRecentFeatures({int limit = 14}) {
    return (select(nightlyFeatures)
          ..orderBy([(f) => OrderingTerm.desc(f.date)])
          ..limit(limit))
        .watch();
  }
}

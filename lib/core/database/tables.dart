import 'package:drift/drift.dart';

/// Alarm configurations
class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withDefault(const Constant('Alarm'))();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get daysOfWeek => text()(); // JSON array like [1,2,3,4,5] for Mon-Fri
  TextColumn get soundFile => text().nullable()();
  IntColumn get snoozeDuration => integer().withDefault(const Constant(5))(); // minutes
  IntColumn get maxSnoozes => integer().withDefault(const Constant(3))();
  BoolColumn get vibrate => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Sleep tracking entries (after alarm dismissal interview)
class SleepEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get bedTime => dateTime().nullable()();
  DateTimeColumn get wakeTime => dateTime().nullable()();
  IntColumn get qualityRating => integer().nullable()(); // 1-5
  IntColumn get moodRating => integer().nullable()(); // 1-5
  TextColumn get dreamDescription => text().nullable()();
  TextColumn get transcription => text().nullable()(); // Full voice transcription
  TextColumn get llmSummary => text().nullable()(); // LLM analysis
  TextColumn get tags => text().nullable()(); // JSON: full extracted data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Evening diary entries
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get transcription => text().nullable()();
  TextColumn get llmSummary => text().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get stressors => text().nullable()(); // JSON array
  TextColumn get gratitude => text().nullable()(); // JSON array
  TextColumn get tomorrowIntentions => text().nullable()();
  IntColumn get overallDayRating => integer().nullable()(); // 1-5
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Meal photo entries
class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack
  TextColumn get photoPath => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get llmAnalysis => text().nullable()();
  TextColumn get nutritionNotes => text().nullable()();
  TextColumn get extractedData => text().nullable()(); // JSON: MealExtractionData
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Conversation messages (for LLM context)
class ConversationMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()(); // Groups messages in a conversation
  TextColumn get sessionType => text()(); // 'morning_interview', 'evening_diary', 'meal_checkin'
  TextColumn get role => text()(); // 'user', 'assistant', 'system'
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// ============================================================
/// FEATURE ENGINEERING TABLE
/// One row per "sleep night" — the atomic unit of analysis.
/// Computed from raw data after each morning interview completes.
/// ============================================================
class NightlyFeatures extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The date this night represents (the morning-of date, e.g., woke up June 1 → date is June 1)
  DateTimeColumn get date => dateTime()();

  // --- Sleep metrics (from morning interview extraction) ---
  IntColumn get sleepQuality => integer().nullable()(); // 1-5
  IntColumn get moodMorning => integer().nullable()(); // 1-5
  IntColumn get energyLevel => integer().nullable()(); // 1-5
  RealColumn get sleepDurationHours => real().nullable()();
  IntColumn get wakeUpCount => integer().nullable()();
  BoolColumn get dreamRecalled => boolean().nullable()();
  TextColumn get dreamValence => text().nullable()(); // positive/negative/neutral/mixed
  TextColumn get physicalSymptoms => text().nullable()(); // JSON array

  // --- Evening diary metrics (from previous evening) ---
  IntColumn get dayRating => integer().nullable()(); // 1-5
  IntColumn get stressLevel => integer().nullable()(); // 1-5
  TextColumn get moodEvening => text().nullable()();
  IntColumn get stressorCount => integer().nullable()();
  IntColumn get gratitudeCount => integer().nullable()();
  BoolColumn get diaryCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get unresolvedWorryCount => integer().nullable()();

  // --- Lifestyle flags (from diary + meal extraction) ---
  BoolColumn get exercisedToday => boolean().nullable()();
  BoolColumn get hadAlcohol => boolean().nullable()();
  BoolColumn get caffeineAfter2pm => boolean().nullable()();
  BoolColumn get screenBeforeBed => boolean().nullable()();
  BoolColumn get lateMeal => boolean().nullable()(); // meal after 8 PM
  BoolColumn get heavyMealEvening => boolean().nullable()();
  BoolColumn get socialInteraction => boolean().nullable()();
  BoolColumn get workedLate => boolean().nullable()();

  // --- Meal summary ---
  IntColumn get mealCount => integer().nullable()(); // how many meals logged
  BoolColumn get caffeineInMeals => boolean().nullable()();
  BoolColumn get alcoholInMeals => boolean().nullable()();
  BoolColumn get sugarHeavyMeal => boolean().nullable()();

  // --- Temporal context ---
  IntColumn get dayOfWeek => integer().nullable()(); // 1=Mon, 7=Sun
  BoolColumn get isWeekend => boolean().nullable()();

  // --- Computed scores ---
  RealColumn get compositeScore => real().nullable()(); // weighted combination
  TextColumn get overallSentiment => text().nullable()(); // from morning

  DateTimeColumn get computedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Weekly aggregated reports
class WeeklyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStart => dateTime()();
  DateTimeColumn get weekEnd => dateTime()();
  RealColumn get avgSleepQuality => real().nullable()();
  RealColumn get avgMoodMorning => real().nullable()();
  RealColumn get avgSleepDuration => real().nullable()();
  RealColumn get avgStressLevel => real().nullable()();
  IntColumn get daysWithDiary => integer().nullable()();
  IntColumn get totalNights => integer().nullable()();
  TextColumn get topCorrelations => text().nullable()(); // JSON: top findings
  TextColumn get llmNarrative => text().nullable()(); // AI-generated report
  TextColumn get recommendations => text().nullable()(); // JSON array
  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Proactive nudges / suggestions
class Nudges extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get nudgeType => text()(); // 'reminder', 'insight', 'warning', 'encouragement'
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get triggerReason => text().nullable()(); // why this nudge was generated
  BoolColumn get shown => boolean().withDefault(const Constant(false))();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

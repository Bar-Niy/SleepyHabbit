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
  TextColumn get tags => text().nullable()(); // JSON array of tags
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

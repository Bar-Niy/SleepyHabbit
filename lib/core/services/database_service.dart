import 'dart:io';
import 'package:sleepy_habbit/core/database/app_database.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  late AppDatabase _database;

  AppDatabase get database => _database;

  Future<void> initialize() async {
    _database = AppDatabase();
  }

  Future<void> close() async {
    await _database.close();
  }

  Future<File> getDatabaseFile() async {
    return _database.getDatabaseFile();
  }
}

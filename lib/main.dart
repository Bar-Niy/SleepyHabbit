import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/app.dart';
import 'package:sleepy_habbit/core/services/notification_service.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await NotificationService.instance.initialize();
  await DatabaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: SleepyHabbitApp(),
    ),
  );
}

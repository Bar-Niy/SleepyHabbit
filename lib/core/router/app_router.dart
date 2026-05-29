import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/core/models/user_profile.dart';
import 'package:sleepy_habbit/features/home/screens/home_screen.dart';
import 'package:sleepy_habbit/features/alarm/screens/alarm_screen.dart';
import 'package:sleepy_habbit/features/alarm/screens/alarm_edit_screen.dart';
import 'package:sleepy_habbit/features/interview/screens/morning_interview_screen.dart';
import 'package:sleepy_habbit/features/diary/screens/evening_diary_screen.dart';
import 'package:sleepy_habbit/features/meals/screens/meal_capture_screen.dart';
import 'package:sleepy_habbit/features/insights/screens/insights_screen.dart';
import 'package:sleepy_habbit/features/settings/screens/settings_screen.dart';
import 'package:sleepy_habbit/features/legal/screens/terms_screen.dart';
import 'package:sleepy_habbit/features/legal/screens/privacy_screen.dart';
import 'package:sleepy_habbit/features/onboarding/screens/onboarding_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final profile = await UserProfile.load();
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!profile.completedOnboarding && !isOnboarding) {
        return '/onboarding';
      }
      if (profile.completedOnboarding && isOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/alarms',
        name: 'alarms',
        builder: (context, state) => const AlarmScreen(),
      ),
      GoRoute(
        path: '/alarms/edit',
        name: 'alarm-edit',
        builder: (context, state) {
          final alarmId = state.uri.queryParameters['id'];
          return AlarmEditScreen(alarmId: alarmId);
        },
      ),
      GoRoute(
        path: '/interview',
        name: 'morning-interview',
        builder: (context, state) => const MorningInterviewScreen(),
      ),
      GoRoute(
        path: '/diary',
        name: 'evening-diary',
        builder: (context, state) => const EveningDiaryScreen(),
      ),
      GoRoute(
        path: '/meals/capture',
        name: 'meal-capture',
        builder: (context, state) => const MealCaptureScreen(),
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  );
});

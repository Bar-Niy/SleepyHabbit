import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// User profile data collected during onboarding
class UserProfile {
  final String? name;
  final int? targetSleepHours; // 6-9
  final String? typicalBedTime; // e.g. "11:00 PM"
  final String? typicalWakeTime; // e.g. "7:00 AM"
  final List<String> sleepIssues; // e.g. ["falling_asleep", "staying_asleep", "waking_early"]
  final List<String> knownFactors; // e.g. ["caffeine", "screen_time", "stress", "late_meals"]
  final String? sleepGoal; // what they want to improve
  final bool hasPartner; // shares bed?
  final bool hasPets; // pets in bedroom?
  final String? workSchedule; // "regular", "shift", "freelance"
  final bool completedOnboarding;

  UserProfile({
    this.name,
    this.targetSleepHours,
    this.typicalBedTime,
    this.typicalWakeTime,
    this.sleepIssues = const [],
    this.knownFactors = const [],
    this.sleepGoal,
    this.hasPartner = false,
    this.hasPets = false,
    this.workSchedule,
    this.completedOnboarding = false,
  });

  UserProfile copyWith({
    String? name,
    int? targetSleepHours,
    String? typicalBedTime,
    String? typicalWakeTime,
    List<String>? sleepIssues,
    List<String>? knownFactors,
    String? sleepGoal,
    bool? hasPartner,
    bool? hasPets,
    String? workSchedule,
    bool? completedOnboarding,
  }) {
    return UserProfile(
      name: name ?? this.name,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      typicalBedTime: typicalBedTime ?? this.typicalBedTime,
      typicalWakeTime: typicalWakeTime ?? this.typicalWakeTime,
      sleepIssues: sleepIssues ?? this.sleepIssues,
      knownFactors: knownFactors ?? this.knownFactors,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      hasPartner: hasPartner ?? this.hasPartner,
      hasPets: hasPets ?? this.hasPets,
      workSchedule: workSchedule ?? this.workSchedule,
      completedOnboarding: completedOnboarding ?? this.completedOnboarding,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'target_sleep_hours': targetSleepHours,
        'typical_bed_time': typicalBedTime,
        'typical_wake_time': typicalWakeTime,
        'sleep_issues': sleepIssues,
        'known_factors': knownFactors,
        'sleep_goal': sleepGoal,
        'has_partner': hasPartner,
        'has_pets': hasPets,
        'work_schedule': workSchedule,
        'completed_onboarding': completedOnboarding,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      targetSleepHours: json['target_sleep_hours'] as int?,
      typicalBedTime: json['typical_bed_time'] as String?,
      typicalWakeTime: json['typical_wake_time'] as String?,
      sleepIssues: (json['sleep_issues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      knownFactors: (json['known_factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sleepGoal: json['sleep_goal'] as String?,
      hasPartner: json['has_partner'] as bool? ?? false,
      hasPets: json['has_pets'] as bool? ?? false,
      workSchedule: json['work_schedule'] as String?,
      completedOnboarding: json['completed_onboarding'] as bool? ?? false,
    );
  }

  /// Persist to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(toJson()));
  }

  /// Load from SharedPreferences
  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_profile');
    if (jsonStr == null) return UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return UserProfile();
    }
  }
}

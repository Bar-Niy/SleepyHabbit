import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/models/user_profile.dart';

class OnboardingState {
  final int currentPage;
  final UserProfile profile;

  OnboardingState({
    this.currentPage = 0,
    UserProfile? profile,
  }) : profile = profile ?? UserProfile();

  OnboardingState copyWith({
    int? currentPage,
    UserProfile? profile,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      profile: profile ?? this.profile,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void nextPage() {
    if (state.currentPage < 4) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void updateProfile(UserProfile profile) {
    state = state.copyWith(profile: profile);
  }

  Future<void> completeOnboarding() async {
    final finalProfile = state.profile.copyWith(completedOnboarding: true);
    await finalProfile.save();
    state = state.copyWith(profile: finalProfile);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

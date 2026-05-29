import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: May 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, installing, or using SleepyHabbit ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the App.',
              theme: theme,
            ),
            _Section(
              title: '2. Description of Service',
              content:
                  'SleepyHabbit is a personal sleep improvement application that uses voice recording, AI-powered conversations, and data tracking to help users understand and improve their sleep patterns. The App is NOT a medical device and does not provide medical advice.',
              theme: theme,
            ),
            _Section(
              title: '3. Health Disclaimer',
              content:
                  'The App is designed for general wellness purposes only. It is not intended to diagnose, treat, cure, or prevent any disease or health condition. The AI-generated insights are based on patterns in your self-reported data and should not be considered medical advice. Always consult a qualified healthcare professional for sleep disorders or health concerns.',
              theme: theme,
            ),
            _Section(
              title: '4. Data Collection & Storage',
              content:
                  'All data (voice recordings, transcriptions, diary entries, meal photos) is stored locally on your device by default. You may optionally enable cloud backup to Google Drive, which is governed by Google\'s own terms of service. We do not have access to your backed-up data.',
              theme: theme,
            ),
            _Section(
              title: '5. AI Processing',
              content:
                  'The App uses AI language models to generate questions and analyze your responses. When using a local AI model, all processing happens on your device. If configured to use an external AI service, your conversation data will be sent to that service provider. You are responsible for reviewing the privacy policies of any third-party AI service you configure.',
              theme: theme,
            ),
            _Section(
              title: '6. Voice Recording Consent',
              content:
                  'By using the voice features of the App, you consent to your voice being recorded, transcribed, and stored locally. Recordings are used solely for the purpose of creating your sleep diary and are never shared without your explicit action.',
              theme: theme,
            ),
            _Section(
              title: '7. User Responsibilities',
              content:
                  'You are responsible for:\n- The accuracy of information you provide\n- Maintaining the security of your device\n- Managing your backup settings\n- Reviewing and configuring AI service connections\n- Not relying on the App for medical decisions',
              theme: theme,
            ),
            _Section(
              title: '8. Limitation of Liability',
              content:
                  'The App is provided "as is" without warranties of any kind. We are not liable for any health decisions made based on App insights, data loss due to device failure, or any indirect damages arising from use of the App.',
              theme: theme,
            ),
            _Section(
              title: '9. Changes to Terms',
              content:
                  'We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the updated terms.',
              theme: theme,
            ),
            _Section(
              title: '10. Contact',
              content:
                  'For questions about these Terms, please contact us at support@sleepyhabbit.app',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final ThemeData theme;

  const _Section({
    required this.title,
    required this.content,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

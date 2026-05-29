import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
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
            const SizedBox(height: 16),
            _HighlightBox(
              text:
                  'TL;DR: Your data stays on YOUR device. We don\'t collect, transmit, or sell any personal data. Cloud backups go only to YOUR Google Drive.',
              theme: theme,
            ),
            const SizedBox(height: 24),
            _Section(
              title: '1. Data We Collect',
              content:
                  'The App collects the following data, all stored locally on your device:\n\n'
                  '- Sleep schedule and quality ratings\n'
                  '- Voice recordings and their transcriptions\n'
                  '- AI-generated conversation logs\n'
                  '- Meal photos and descriptions\n'
                  '- Evening diary entries\n'
                  '- Alarm settings and preferences',
              theme: theme,
            ),
            _Section(
              title: '2. How Data is Stored',
              content:
                  'All data is stored in a local SQLite database on your device. The database file is located in the app\'s private storage directory, inaccessible to other apps.\n\n'
                  'If you enable Google Drive backup, an encrypted copy of your database is stored in your personal Google Drive account, in a folder named "SleepyHabbit_Backups".',
              theme: theme,
            ),
            _Section(
              title: '3. Data Sharing',
              content:
                  'We do NOT:\n'
                  '- Collect any data on our servers\n'
                  '- Share data with third parties\n'
                  '- Use your data for advertising\n'
                  '- Sell your data\n'
                  '- Have access to your backups\n\n'
                  'The only external data transmission occurs when:\n'
                  '- You configure an external AI service (your conversations are sent to that service)\n'
                  '- You enable Google Drive backup (data goes to your Drive account)',
              theme: theme,
            ),
            _Section(
              title: '4. AI/LLM Processing',
              content:
                  'When using a LOCAL AI model (default), all processing happens on your device with zero network transmission.\n\n'
                  'If you configure an external AI provider (e.g., Ollama on another machine, Groq, OpenAI), your conversation messages will be sent to that provider. You should review their privacy policy. We recommend using a local model for maximum privacy.',
              theme: theme,
            ),
            _Section(
              title: '5. Voice Recordings',
              content:
                  'Voice recordings are:\n'
                  '- Processed locally for speech-to-text transcription\n'
                  '- Stored only as text transcriptions (audio is discarded after transcription)\n'
                  '- Never transmitted to any server unless you configure an external STT service\n'
                  '- Deletable at any time through the App settings',
              theme: theme,
            ),
            _Section(
              title: '6. Photos',
              content:
                  'Meal photos are stored locally on your device in the app\'s private directory. They are included in Google Drive backups if enabled. Photos are never transmitted elsewhere.',
              theme: theme,
            ),
            _Section(
              title: '7. Data Deletion',
              content:
                  'You can delete all your data at any time by:\n'
                  '- Uninstalling the App (removes all local data)\n'
                  '- Using the "Clear Data" option in Settings\n'
                  '- Manually deleting backup files from Google Drive',
              theme: theme,
            ),
            _Section(
              title: '8. Children\'s Privacy',
              content:
                  'The App is not designed for children under 13. We do not knowingly collect data from children.',
              theme: theme,
            ),
            _Section(
              title: '9. Security',
              content:
                  'Your data is protected by:\n'
                  '- Android/iOS app sandboxing (other apps cannot access your data)\n'
                  '- Your device\'s lock screen security\n'
                  '- Google Drive\'s encryption for cloud backups\n\n'
                  'We recommend enabling device encryption and a strong lock screen password.',
              theme: theme,
            ),
            _Section(
              title: '10. Changes to This Policy',
              content:
                  'We will notify you of any changes to this Privacy Policy through the App. Continued use after changes constitutes acceptance.',
              theme: theme,
            ),
            _Section(
              title: '11. Contact',
              content:
                  'For privacy questions or data requests, contact us at privacy@sleepyhabbit.app',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _HighlightBox({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/core/services/backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  String? _lastBackupStr;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final backup = ref.read(backupServiceProvider);
    final lastBackup = await backup.getLastBackupTime();
    if (lastBackup != null && mounted) {
      setState(() {
        _lastBackupStr = _formatBackupTime(lastBackup);
      });
    }
  }

  String _formatBackupTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backup = ref.read(backupServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Backup Section
          _SectionHeader(title: 'Backup & Sync', theme: theme),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Google Drive Backup'),
            subtitle: Text(
              backup.isSignedIn
                  ? 'Connected${_lastBackupStr != null ? ' - Last: $_lastBackupStr' : ''}'
                  : 'Not connected',
            ),
            trailing: backup.isSignedIn
                ? IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await backup.signOut();
                      setState(() {});
                    },
                  )
                : null,
            onTap: () async {
              if (!backup.isSignedIn) {
                final success = await backup.signIn();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connected to Google Drive')),
                  );
                  setState(() {});
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Now'),
            subtitle: const Text('Manually backup your data'),
            trailing: _isBackingUp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isBackingUp
                ? null
                : () async {
                    setState(() => _isBackingUp = true);
                    final success = await backup.backup();
                    if (mounted) {
                      setState(() => _isBackingUp = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Backup successful!'
                              : 'Backup failed. Check connection.'),
                        ),
                      );
                      _loadBackupInfo();
                    }
                  },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from Backup'),
            subtitle: const Text('Restore data from Google Drive'),
            onTap: () => _showRestoreDialog(context),
          ),
          const Divider(),

          // LLM Configuration
          _SectionHeader(title: 'AI Assistant', theme: theme),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('LLM Configuration'),
            subtitle: const Text('Configure AI backend'),
            onTap: () => _showLlmConfigDialog(context),
          ),
          const Divider(),

          // Notifications
          _SectionHeader(title: 'Notifications', theme: theme),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Evening Diary Reminder'),
            subtitle: const Text('Remind to write diary before bed'),
            value: true,
            onChanged: (val) {
              // TODO: Save preference
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.restaurant),
            title: const Text('Meal Photo Reminders'),
            subtitle: const Text('Remind to log meals'),
            value: true,
            onChanged: (val) {
              // TODO: Save preference
            },
          ),
          const Divider(),

          // Legal
          _SectionHeader(title: 'Legal', theme: theme),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () => context.push('/privacy'),
          ),
          const Divider(),

          // About
          _SectionHeader(title: 'About', theme: theme),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('SleepyHabbit'),
            subtitle: Text('Version 1.0.0'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'This will replace your current data with the latest backup. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final backup = ref.read(backupServiceProvider);
              final success = await backup.restore();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Data restored successfully!'
                        : 'Restore failed.'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showLlmConfigDialog(BuildContext context) {
    final urlController = TextEditingController(text: 'http://localhost:8080');
    final keyController = TextEditingController();
    final modelController = TextEditingController(text: 'llama3.2');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure the LLM backend. Supports any OpenAI-compatible API '
                '(local llama.cpp, Ollama, Groq, etc.)',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  hintText: 'http://localhost:8080',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model name',
                  hintText: 'llama3.2',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final llm = ref.read(llmServiceProvider);
              await llm.saveSettings(
                baseUrl: urlController.text,
                apiKey: keyController.text.isNotEmpty
                    ? keyController.text
                    : null,
                model: modelController.text,
              );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

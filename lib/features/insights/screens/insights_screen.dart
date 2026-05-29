import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _analysisText;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InsightMetric(
                          label: 'Avg Quality',
                          value: '3.8',
                          suffix: '/5',
                          trend: '+0.3',
                          trendUp: true,
                          theme: theme,
                        ),
                        _InsightMetric(
                          label: 'Avg Duration',
                          value: '7.1',
                          suffix: 'hrs',
                          trend: '-0.2',
                          trendUp: false,
                          theme: theme,
                        ),
                        _InsightMetric(
                          label: 'Entries',
                          value: '5',
                          suffix: '/7',
                          trend: '',
                          trendUp: true,
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'AI Analysis',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isLoading ? null : _generateAnalysis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_analysisText != null)
                      Text(
                        _analysisText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      )
                    else
                      Text(
                        'Tap the refresh button to get personalized insights based on your sleep data, diary entries, and meal patterns.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tips section
            Text(
              'Sleep Tips',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _TipCard(
              icon: Icons.no_food,
              title: 'Avoid late heavy meals',
              subtitle:
                  'Eating within 2 hours of bedtime can disrupt sleep quality',
              theme: theme,
            ),
            _TipCard(
              icon: Icons.book,
              title: 'Keep a thought diary',
              subtitle:
                  'Writing down worries before bed reduces racing thoughts',
              theme: theme,
            ),
            _TipCard(
              icon: Icons.schedule,
              title: 'Consistent wake time',
              subtitle:
                  'Waking at the same time daily trains your body clock',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAnalysis() async {
    setState(() => _isLoading = true);

    try {
      final llm = ref.read(llmServiceProvider);
      final db = DatabaseService.instance.database;

      // Gather data
      final sleepEntries = await db.sleepEntryDao.getAllEntries();
      final diaryEntries = await db.diaryEntryDao.getAllEntries();
      final mealEntries = await db.mealEntryDao.getAllEntries();

      final sleepJson = sleepEntries
          .map((e) =>
              '${e.date}: quality=${e.qualityRating}, mood=${e.moodRating}, summary=${e.llmSummary}')
          .join('\n');
      final diaryJson = diaryEntries
          .map((e) => '${e.date}: ${e.llmSummary}')
          .join('\n');
      final mealJson = mealEntries
          .map((e) =>
              '${e.date} ${e.mealType}: ${e.description} - ${e.llmAnalysis}')
          .join('\n');

      final analysis = await llm.analyzeSleepPatterns(
        sleepDataJson: sleepJson,
        diaryDataJson: diaryJson,
        mealDataJson: mealJson,
      );

      setState(() => _analysisText = analysis);
    } catch (e) {
      setState(() => _analysisText = 'Unable to generate analysis: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _InsightMetric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final String trend;
  final bool trendUp;
  final ThemeData theme;

  const _InsightMetric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.trend,
    required this.trendUp,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextSpan(
                text: suffix,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (trend.isNotEmpty)
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              color: trendUp ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/services/feature_engineering_service.dart';
import 'package:sleepy_habbit/core/services/weekly_report_service.dart';
import 'package:sleepy_habbit/core/services/monthly_analysis_service.dart';
import 'package:sleepy_habbit/core/services/nudge_service.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MonthlyAnalysis? _monthlyAnalysis;
  List<FeatureCorrelation> _correlations = [];
  bool _isLoading = false;
  String? _weeklyNarrative;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final features = ref.read(featureEngineeringProvider);
      _correlations = await features.getTopCorrelations(days: 30);

      // Try to load latest weekly report
      final weeklyService = ref.read(weeklyReportServiceProvider);
      if (await weeklyService.shouldGenerateReport()) {
        final report = await weeklyService.generateWeeklyReport();
        if (report != null) {
          _weeklyNarrative = report.llmNarrative;
        }
      }
    } catch (e) {
      // Data not available yet - that's fine
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Patterns'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _WeeklyTab(
                  narrative: _weeklyNarrative,
                  onRefresh: _generateWeeklyReport,
                  theme: theme,
                ),
                _MonthlyTab(
                  analysis: _monthlyAnalysis,
                  onGenerate: _generateMonthlyReport,
                  theme: theme,
                ),
                _PatternsTab(
                  correlations: _correlations,
                  theme: theme,
                ),
              ],
            ),
    );
  }

  Future<void> _generateWeeklyReport() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(weeklyReportServiceProvider);
      final report = await service.generateWeeklyReport();
      if (report != null) {
        setState(() => _weeklyNarrative = report.llmNarrative);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _generateMonthlyReport() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(monthlyAnalysisServiceProvider);
      final analysis = await service.generateMonthlyAnalysis();
      setState(() => _monthlyAnalysis = analysis);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }
}

// --- Weekly Tab ---

class _WeeklyTab extends StatelessWidget {
  final String? narrative;
  final VoidCallback onRefresh;
  final ThemeData theme;

  const _WeeklyTab({
    required this.narrative,
    required this.onRefresh,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week\'s Report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (narrative != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Sleep Coach',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      narrative!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep tracking for a few more days',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weekly reports will appear after at least 3 days of data. '
                      'The more consistent you are, the better the insights.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Monthly Tab ---

class _MonthlyTab extends StatelessWidget {
  final MonthlyAnalysis? analysis;
  final VoidCallback onGenerate;
  final ThemeData theme;

  const _MonthlyTab({
    required this.analysis,
    required this.onGenerate,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Monthly Analysis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a comprehensive analysis of your sleep patterns, '
                'lifestyle correlations, and personalized recommendations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.psychology),
                label: const Text('Generate Report'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats overview
          _StatsGrid(stats: analysis!.stats, theme: theme),
          const SizedBox(height: 20),

          // Trend indicator
          _TrendCard(trends: analysis!.trends, theme: theme),
          const SizedBox(height: 20),

          // Narrative
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly Narrative',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    analysis!.narrative,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Patterns
          if (analysis!.patterns.isNotEmpty) ...[
            Text(
              'Discovered Patterns',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...analysis!.patterns.map(
              (p) => _PatternCard(pattern: p, theme: theme),
            ),
            const SizedBox(height: 20),
          ],

          // Recommendations
          Text(
            'Recommendations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis!.recommendations.map(
            (r) => _RecommendationTile(text: r, theme: theme),
          ),
        ],
      ),
    );
  }
}

// --- Patterns Tab ---

class _PatternsTab extends StatelessWidget {
  final List<FeatureCorrelation> correlations;
  final ThemeData theme;

  const _PatternsTab({
    required this.correlations,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (correlations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.query_stats, size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'Building your pattern map',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'After 7+ days of data, I\'ll show you what affects your sleep quality most.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'What Affects Your Sleep',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sorted by strength of correlation with your sleep quality.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),
        ...correlations.map(
          (c) => _CorrelationBar(correlation: c, theme: theme),
        ),
      ],
    );
  }
}

// --- Widget components ---

class _StatsGrid extends StatelessWidget {
  final MonthlyStats stats;
  final ThemeData theme;

  const _StatsGrid({required this.stats, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: 'Avg Quality',
                        value: '${stats.avgQuality?.toStringAsFixed(1) ?? "-"}/5',
                        theme: theme)),
                Expanded(
                    child: _StatItem(
                        label: 'Duration',
                        value: '${stats.avgDuration?.toStringAsFixed(1) ?? "-"}h',
                        theme: theme)),
                Expanded(
                    child: _StatItem(
                        label: 'Good Nights',
                        value: '${stats.goodNights}',
                        theme: theme)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: 'Bad Nights',
                        value: '${stats.badNights}',
                        theme: theme)),
                Expanded(
                    child: _StatItem(
                        label: 'Diary Rate',
                        value: '${stats.diaryCompletionRate?.toStringAsFixed(0) ?? "-"}%',
                        theme: theme)),
                Expanded(
                    child: _StatItem(
                        label: 'Dreams',
                        value: '${stats.dreamsRecalled}',
                        theme: theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatItem(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final TrendAnalysis trends;
  final ThemeData theme;

  const _TrendCard({required this.trends, required this.theme});

  @override
  Widget build(BuildContext context) {
    final trendIcon = trends.qualityTrend == 'improving'
        ? Icons.trending_up
        : trends.qualityTrend == 'declining'
            ? Icons.trending_down
            : Icons.trending_flat;
    final trendColor = trends.qualityTrend == 'improving'
        ? Colors.green
        : trends.qualityTrend == 'declining'
            ? Colors.red
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(trendIcon, color: trendColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep quality is ${trends.qualityTrend}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Best day: ${trends.bestDayOfWeek} · Worst: ${trends.worstDayOfWeek}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trends.qualityChange != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${trends.qualityChange! > 0 ? "+" : ""}${trends.qualityChange!.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final PatternInsight pattern;
  final ThemeData theme;

  const _PatternCard({required this.pattern, required this.theme});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = {
      'temporal': Icons.schedule,
      'behavioral': Icons.psychology,
      'emotional': Icons.emoji_emotions,
      'nutritional': Icons.restaurant,
    }[pattern.category] ??
        Icons.lightbulb;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(categoryIcon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(pattern.description),
        subtitle: Text(
          '${pattern.category} · ${(pattern.confidence * 100).round()}% confidence',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CorrelationBar extends StatelessWidget {
  final FeatureCorrelation correlation;
  final ThemeData theme;

  const _CorrelationBar({required this.correlation, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPositive = correlation.correlation > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final barWidth = correlation.correlation.abs().clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  correlation.featureName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${isPositive ? "+" : ""}${correlation.correlation.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barWidth,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            correlation.interpretation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _RecommendationTile({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

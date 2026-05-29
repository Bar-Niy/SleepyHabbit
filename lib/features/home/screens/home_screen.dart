import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sleepy_habbit/core/services/nudge_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _nudges = [];

  @override
  void initState() {
    super.initState();
    _loadNudges();
  }

  Future<void> _loadNudges() async {
    try {
      final nudgeService = ref.read(nudgeServiceProvider);
      final nudges = await nudgeService.generateNudges();
      if (mounted) setState(() => _nudges = nudges);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Proactive nudges
                    if (_nudges.isNotEmpty) ...[
                      _NudgeCarousel(nudges: _nudges, theme: theme),
                      const SizedBox(height: 16),
                    ],

                    _SleepSummaryCard(theme: theme),
                    const SizedBox(height: 16),
                    _QuickActionsRow(theme: theme),
                    const SizedBox(height: 24),
                    Text(
                      'Today',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TodayTimeline(theme: theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break; // Already on home
            case 1:
              context.push('/alarms');
            case 2:
              context.push('/insights');
            case 3:
              context.push('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Time to wind down 🌙';
  }
}

class _SleepSummaryCard extends StatelessWidget {
  final ThemeData theme;
  const _SleepSummaryCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Last Night\'s Sleep',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SleepStat(
                  label: 'Duration',
                  value: '7h 23m',
                  icon: Icons.schedule,
                  theme: theme,
                ),
                _SleepStat(
                  label: 'Quality',
                  value: '4/5',
                  icon: Icons.star,
                  theme: theme,
                ),
                _SleepStat(
                  label: 'Mood',
                  value: '😊',
                  icon: Icons.emoji_emotions,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;

  const _SleepStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

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
        const SizedBox(height: 4),
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

class _QuickActionsRow extends StatelessWidget {
  final ThemeData theme;
  const _QuickActionsRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.mic,
            label: 'Diary',
            color: theme.colorScheme.primary,
            onTap: () => context.push('/diary'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.camera_alt,
            label: 'Meal',
            color: theme.colorScheme.secondary,
            onTap: () => context.push('/meals/capture'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.chat_bubble,
            label: 'Check-in',
            color: theme.colorScheme.tertiary,
            onTap: () => context.push('/interview'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTimeline extends StatelessWidget {
  final ThemeData theme;
  const _TodayTimeline({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          time: '7:30 AM',
          title: 'Woke up',
          subtitle: 'Morning interview completed',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          theme: theme,
        ),
        _TimelineItem(
          time: '8:15 AM',
          title: 'Breakfast',
          subtitle: 'Photo captured',
          icon: Icons.restaurant,
          color: Colors.green,
          theme: theme,
        ),
        _TimelineItem(
          time: '10:00 PM',
          title: 'Evening diary',
          subtitle: 'Pending',
          icon: Icons.book,
          color: theme.colorScheme.primary,
          theme: theme,
          isPending: true,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final bool isPending;

  const _TimelineItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.theme,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPending ? color.withOpacity(0.2) : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: isPending
                  ? Border.all(color: color, width: 2, strokeAlign: BorderSide.strokeAlignOutside)
                  : null,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _NudgeCarousel extends StatelessWidget {
  final List<dynamic> nudges;
  final ThemeData theme;

  const _NudgeCarousel({required this.nudges, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nudges.length,
        itemBuilder: (context, index) {
          final nudge = nudges[index];
          return _NudgeCard(nudge: nudge, theme: theme);
        },
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final dynamic nudge;
  final ThemeData theme;

  const _NudgeCard({required this.nudge, required this.theme});

  @override
  Widget build(BuildContext context) {
    final nudgeType = nudge.nudgeType;
    final icon = _iconForType(nudgeType);
    final color = _colorForType(nudgeType);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nudge.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  nudge.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reminder': return Icons.notifications_active;
      case 'insight': return Icons.lightbulb;
      case 'warning': return Icons.warning_amber;
      case 'encouragement': return Icons.celebration;
      default: return Icons.info;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'reminder': return Colors.blue;
      case 'insight': return Colors.purple;
      case 'warning': return Colors.orange;
      case 'encouragement': return Colors.green;
      default: return Colors.grey;
    }
  }
}

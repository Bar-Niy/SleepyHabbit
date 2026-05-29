import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/features/interview/providers/interview_provider.dart';

class MorningInterviewScreen extends ConsumerStatefulWidget {
  const MorningInterviewScreen({super.key});

  @override
  ConsumerState<MorningInterviewScreen> createState() =>
      _MorningInterviewScreenState();
}

class _MorningInterviewScreenState
    extends ConsumerState<MorningInterviewScreen> {
  @override
  void initState() {
    super.initState();
    // Start the interview when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interviewProvider.notifier).startInterview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interview = ref.watch(interviewProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Morning Check-in',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _showExitDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Conversation history
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: interview.messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex =
                        interview.messages.length - 1 - index;
                    final msg = interview.messages[reversedIndex];
                    return _ChatBubble(
                      message: msg.content,
                      isUser: msg.role == 'user',
                      theme: theme,
                    );
                  },
                ),
              ),

              // Status indicator
              if (interview.state == InterviewState.speaking)
                _StatusIndicator(
                  icon: Icons.volume_up,
                  label: 'Speaking...',
                  color: theme.colorScheme.primary,
                ),
              if (interview.state == InterviewState.listening)
                _StatusIndicator(
                  icon: Icons.mic,
                  label: 'Listening...',
                  color: Colors.red,
                ),
              if (interview.state == InterviewState.processing)
                _StatusIndicator(
                  icon: Icons.psychology,
                  label: 'Thinking...',
                  color: Colors.orange,
                ),

              const SizedBox(height: 16),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic button
                  _CircleButton(
                    icon: interview.state == InterviewState.listening
                        ? Icons.stop
                        : Icons.mic,
                    color: interview.state == InterviewState.listening
                        ? Colors.red
                        : theme.colorScheme.primary,
                    size: 64,
                    onPressed: () {
                      if (interview.state == InterviewState.listening) {
                        ref.read(interviewProvider.notifier).stopListening();
                      } else if (interview.state == InterviewState.idle ||
                          interview.state == InterviewState.waitingForInput) {
                        ref.read(interviewProvider.notifier).startListening();
                      }
                    },
                  ),
                  // Skip button
                  _CircleButton(
                    icon: Icons.skip_next,
                    color: theme.colorScheme.secondary,
                    size: 48,
                    onPressed: () {
                      ref.read(interviewProvider.notifier).skipQuestion();
                    },
                  ),
                  // Done button
                  _CircleButton(
                    icon: Icons.check,
                    color: Colors.green,
                    size: 48,
                    onPressed: () {
                      ref.read(interviewProvider.notifier).finishInterview();
                      context.pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End interview?'),
        content: const Text(
            'Your responses so far will be saved. You can continue later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(interviewProvider.notifier).finishInterview();
              context.pop();
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final ThemeData theme;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }
}

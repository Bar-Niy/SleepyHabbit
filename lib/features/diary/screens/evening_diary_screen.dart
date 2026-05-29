import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/features/diary/providers/diary_provider.dart';

class EveningDiaryScreen extends ConsumerStatefulWidget {
  const EveningDiaryScreen({super.key});

  @override
  ConsumerState<EveningDiaryScreen> createState() =>
      _EveningDiaryScreenState();
}

class _EveningDiaryScreenState extends ConsumerState<EveningDiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diaryProvider.notifier).startDiarySession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = ref.watch(diaryProvider);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evening Diary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Let\'s wind down together',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(diaryProvider.notifier).finishSession();
                      context.pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress indicator
              LinearProgressIndicator(
                value: diary.progress,
                backgroundColor:
                    theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 20),

              // Conversation
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: diary.messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex =
                        diary.messages.length - 1 - index;
                    final msg = diary.messages[reversedIndex];
                    return _DiaryBubble(
                      message: msg.content,
                      isUser: msg.role == 'user',
                      theme: theme,
                    );
                  },
                ),
              ),

              // Input area
              const SizedBox(height: 12),
              _InputArea(
                isListening: diary.state == DiaryState.listening,
                isSpeaking: diary.state == DiaryState.speaking,
                onMicPressed: () {
                  if (diary.state == DiaryState.listening) {
                    ref.read(diaryProvider.notifier).stopListening();
                  } else {
                    ref.read(diaryProvider.notifier).startListening();
                  }
                },
                onDonePressed: () {
                  ref.read(diaryProvider.notifier).finishSession();
                  context.pop();
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final ThemeData theme;

  const _DiaryBubble({
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
              ? theme.colorScheme.primary.withOpacity(0.9)
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
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback onMicPressed;
  final VoidCallback onDonePressed;
  final ThemeData theme;

  const _InputArea({
    required this.isListening,
    required this.isSpeaking,
    required this.onMicPressed,
    required this.onDonePressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isListening
                  ? 'Listening...'
                  : isSpeaking
                      ? 'Speaking...'
                      : 'Tap the mic to talk',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isListening ? Icons.stop : Icons.mic,
              color: isListening ? Colors.red : theme.colorScheme.primary,
            ),
            onPressed: onMicPressed,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDonePressed,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

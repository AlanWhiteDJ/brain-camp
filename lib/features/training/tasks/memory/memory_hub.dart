/// Memory Training Hub
/// Entry point for memory games: Corsi, N-Back, Pattern Memory
///
/// Displays 3 game cards with descriptions and difficulty info.
/// Each card navigates to its respective game screen.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'corsi_screen.dart';
import 'nback_screen.dart';
import 'grid_screen.dart';

class MemoryHub extends StatelessWidget {
  final Map<String, dynamic> childProfile;

  const MemoryHub({super.key, required this.childProfile});

  @override
  Widget build(BuildContext context) {
    final nickname = childProfile['nickname'] ?? '宝贝';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('🧠 记忆力训练'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nickname，来锻炼记忆力吧！',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '选一个游戏开始训练 💪',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Game 1: Corsi Block-Tapping
              _GameCard(
                emoji: '🧱',
                title: '记忆小路',
                subtitle: 'Corsi Block-Tapping',
                description: '方块按顺序亮起，你按同样的顺序点回去！考验你的视觉空间记忆。',
                difficulty: '路线越长越难哦',
                color: AppTheme.purple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CorsiScreen(childProfile: childProfile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Game 2: N-Back
              _GameCard(
                emoji: '🔍',
                title: '回看一下',
                subtitle: 'N-Back 工作记忆',
                description: '方块一个一个亮起来，如果和前面第2个一样就点「对」！训练你的工作记忆。',
                difficulty: '间隔越来越短哦',
                color: AppTheme.calmBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NBackScreen(childProfile: childProfile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Game 3: Pattern Memory
              _GameCard(
                emoji: '🟩',
                title: '图案记忆',
                subtitle: 'Pattern Memory',
                description: '先看一眼格子里亮起的图案，消失后把它一模一样地点回来！',
                difficulty: '格子越来越大哦',
                color: AppTheme.warmOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GridScreen(childProfile: childProfile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Tip card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.correctGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.correctGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '坚持每天训练，记忆力会越来越好！每个游戏难度都会自动调整，慢慢来不用急。',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final String difficulty;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.difficulty,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill, color: color, size: 32),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

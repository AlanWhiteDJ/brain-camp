import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'dots_screen.dart';
import 'line_screen.dart';
import 'subitize_screen.dart';

/// Number Sense module hub — gateway to all 3 number sense games.
/// Each card navigates to its game screen with the child profile.
class NumberHub extends StatelessWidget {
  final Map<String, dynamic> childProfile;

  const NumberHub({super.key, required this.childProfile});

  static const _games = [
    _GameInfo(
      emoji: '🔴',
      title: '比比看',
      subtitle: '两边的小圆点，哪边更多？',
      color: Color(0xFF66BB6A),
      routeId: 'dots',
    ),
    _GameInfo(
      emoji: '📏',
      title: '在哪呢',
      subtitle: '把这个数字拖到数轴正确的位置上',
      color: Color(0xFF42A5F5),
      routeId: 'line',
    ),
    _GameInfo(
      emoji: '👁️',
      title: '一眼看',
      subtitle: '一闪而过，多少个小圆点？',
      color: Color(0xFFFF7043),
      routeId: 'subitize',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = childProfile['nickname'] ?? '宝贝';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('数感训练'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header greeting
              Text(
                '$name，来练练数感吧！',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '选一个游戏开始训练',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Game cards — vertical list for larger touch targets
              Expanded(
                child: ListView.separated(
                  itemCount: _games.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return _GameCard(
                      info: game,
                      onTap: () => _launchGame(context, game),
                    );
                  },
                ),
              ),

              // Back button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('返回', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, _GameInfo game) {
    Widget screen;
    switch (game.routeId) {
      case 'dots':
        screen = DotsScreen(childProfile: childProfile);
        break;
      case 'line':
        screen = LineScreen(childProfile: childProfile);
        break;
      case 'subitize':
        screen = SubitizeScreen(childProfile: childProfile);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _GameInfo {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String routeId;

  const _GameInfo({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.routeId,
  });
}

class _GameCard extends StatelessWidget {
  final _GameInfo info;
  final VoidCallback onTap;

  const _GameCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: info.color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(info.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: info.color.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

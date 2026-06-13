import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'simple_screen.dart';
import 'choice_screen.dart';
import 'gonogo_screen.dart';

/// Reaction Speed module hub — gateway to all 3 reaction games.
/// Each card navigates to its game screen with the child profile.
class ReactionHub extends StatelessWidget {
  final Map<String, dynamic> childProfile;

  const ReactionHub({super.key, required this.childProfile});

  static const _games = [
    _GameInfo(
      emoji: '⚡',
      title: '闪电反应',
      subtitle: '看到绿色马上点！越快越好',
      color: AppTheme.warmOrange,
      routeId: 'simple',
    ),
    _GameInfo(
      emoji: '👈👉',
      title: '左右开弓',
      subtitle: '哪边亮就点哪边，锻炼反应和方向',
      color: AppTheme.calmBlue,
      routeId: 'choice',
    ),
    _GameInfo(
      emoji: '🟢',
      title: '绿灯行',
      subtitle: '绿灯点，红灯停。管住小手！',
      color: AppTheme.primaryGreen,
      routeId: 'gonogo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = childProfile['nickname'] ?? '宝贝';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('反应力训练'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name，来练练反应力吧！',
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

              Expanded(
                child: ListView.separated(
                  itemCount: _games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return _GameCard(
                      info: game,
                      onTap: () => _launchGame(context, game),
                    );
                  },
                ),
              ),

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
      case 'simple':
        screen = SimpleScreen(childProfile: childProfile);
        break;
      case 'choice':
        screen = ChoiceScreen(childProfile: childProfile);
        break;
      case 'gonogo':
        screen = GoNogoScreen(childProfile: childProfile);
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

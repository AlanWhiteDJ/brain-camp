import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'cpt_screen.dart';
import 'search_screen.dart';
import 'flanker_screen.dart';

/// Attention module hub — gateway to all 3 attention games.
/// Each card navigates to its game screen with the child profile.
class AttentionHub extends StatelessWidget {
  final Map<String, dynamic> childProfile;

  const AttentionHub({super.key, required this.childProfile});

  static const _games = [
    _GameInfo(
      emoji: '🐑',
      title: '找小羊',
      subtitle: '盯住小羊，别被其他动物骗了',
      color: Color(0xFF42A5F5),
      routeId: 'cpt',
    ),
    _GameInfo(
      emoji: '🔍',
      title: '火眼金睛',
      subtitle: '在人群中找出目标',
      color: Color(0xFFFF7043),
      routeId: 'search',
    ),
    _GameInfo(
      emoji: '🧭',
      title: '指方向',
      subtitle: '只看中间的箭头，别被旁边影响',
      color: Color(0xFFAB47BC),
      routeId: 'flanker',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = childProfile['nickname'] ?? '宝贝';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('专注力训练'),
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
                '$name，来练练专注力吧！',
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

              // Back button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
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
      case 'cpt':
        screen = CptScreen(childProfile: childProfile);
        break;
      case 'search':
        screen = SearchScreen(childProfile: childProfile);
        break;
      case 'flanker':
        screen = FlankerScreen(childProfile: childProfile);
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

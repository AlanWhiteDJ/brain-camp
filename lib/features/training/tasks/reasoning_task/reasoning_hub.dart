import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'pattern_screen.dart';
import 'oddone_screen.dart';
import 'analogy_screen.dart';

/// Reasoning Hub — shows 3 game cards for the child to choose
class ReasoningHubScreen extends StatelessWidget {
  final Map<String, dynamic> childProfile;
  const ReasoningHubScreen({super.key, required this.childProfile});

  String get _nickname => childProfile['nickname'] ?? '宝贝';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('🧠 逻辑推理', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_nickname，来玩推理游戏吧！',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '选一个游戏，看看你有多聪明 ✨',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 28),

              // Game 1: Pattern
              _GameCard(
                emoji: '🧩',
                title: '找规律',
                subtitle: '看看图案有什么规律？\n问号那里应该放什么？',
                color: const Color(0xFFFF9800),
                onTap: () => _navigate(context, const PatternScreen()),
              ),
              const SizedBox(height: 16),

              // Game 2: Odd One Out
              _GameCard(
                emoji: '🔍',
                title: '找不同',
                subtitle: '四个里面有一个不一样\n把它找出来！',
                color: const Color(0xFF42A5F5),
                onTap: () => _navigate(context, const OddOneScreen()),
              ),
              const SizedBox(height: 16),

              // Game 3: Analogies
              _GameCard(
                emoji: '⚖️',
                title: '比一比',
                subtitle: '前面两个的关系，\n后面也应该一样！',
                color: const Color(0xFFAB47BC),
                onTap: () => _navigate(context, const AnalogyScreen()),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChildProfileProvider(
          profile: childProfile,
          child: screen,
        ),
      ),
    );
  }
}

/// Provides childProfile down to game screens without constructor threading
class ChildProfileProvider extends InheritedWidget {
  final Map<String, dynamic> profile;
  const ChildProfileProvider({
    super.key,
    required this.profile,
    required super.child,
  });

  static Map<String, dynamic> of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ChildProfileProvider>();
    return provider?.profile ?? {};
  }

  @override
  bool updateShouldNotify(ChildProfileProvider oldWidget) => profile != oldWidget.profile;
}

/// A single game card in the hub
class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

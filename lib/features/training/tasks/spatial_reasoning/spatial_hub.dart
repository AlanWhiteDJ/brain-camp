import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'rotate_screen.dart';
import 'blocks_screen.dart';
import 'mirror_screen.dart';

class SpatialHubScreen extends StatelessWidget {
  final Map<String, dynamic> childProfile;
  const SpatialHubScreen({super.key, required this.childProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(title: const Text('空间训练'), backgroundColor: const Color(0xFF26C6DA), foregroundColor: Colors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选一个开始练吧！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _GameCard('🔮', '转一转', '把图案在脑子里转过来', '难度：转动角度越来越大', const Color(0xFF26C6DA), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RotateScreen(childProfile: childProfile)));
                    }),
                    _GameCard('🧱', '搭积木', '照着图案把积木拼出来', '难度：积木越来越多，图案越来越复杂', const Color(0xFF00BCD4), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocksScreen(childProfile: childProfile)));
                    }),
                    _GameCard('🪞', '照镜子', '找出镜子里的另一半', '难度：形状越来越像，更难分辨', const Color(0xFF0097A7), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MirrorScreen(childProfile: childProfile)));
                    }),
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
  final String emoji, title, subtitle, difficulty;
  final Color color;
  final VoidCallback onTap;
  const _GameCard(this.emoji, this.title, this.subtitle, this.difficulty, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)]),
          child: Row(
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28)))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(difficulty, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
                ]),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

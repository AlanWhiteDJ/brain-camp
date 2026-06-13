import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'features/profile/profile_screen.dart';
import 'features/training/tasks/cpt/cpt_screen.dart';
import 'features/training/tasks/corsi/corsi_screen.dart';
import 'features/profile/child_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const BrainCampApp());
}

class BrainCampApp extends StatelessWidget {
  const BrainCampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChildProfileState(),
      child: MaterialApp(
        title: 'Brain Camp',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppGate(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Routes to profile creation or home based on whether profile exists
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!LocalStorage.hasProfile) {
      return const ProfileScreen(isFirstTime: true);
    }

    final profile = LocalStorage.loadProfile()!;
    context.read<ChildProfileState>().load(profile);
    return const HomeScreen();
  }
}

/// Home screen with 6 training modules
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _modules = [
    _ModuleInfo('🎯', '专注', '找一找，盯住不放', Color(0xFF42A5F5), 'cpt'),
    _ModuleInfo('🧠', '记忆', '记住位置和顺序', Color(0xFFAB47BC), 'corsi', enabled: true),
    _ModuleInfo('🔢', '数感', '比比大小，估估位置', Color(0xFF66BB6A), 'number'),
    _ModuleInfo('⚡', '反应', '看得快，点得准', Color(0xFFFF7043), 'reaction'),
    _ModuleInfo('🧩', '推理', '找出规律，缺了谁', Color(0xFFFFCA28), 'reasoning'),
    _ModuleInfo('🔮', '空间', '转一转，想一想', Color(0xFF26C6DA), 'spatial'),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ChildProfileState>();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.avatar,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile.nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.age}岁',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                '今天练什么？',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Module grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final m = _modules[index];
                    return _ModuleCard(
                      info: m,
                      onTap: () => _onModuleTap(context, m),
                    );
                  },
                ),
              ),

              // Report button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to report
                  },
                  icon: const Text('📊', style: TextStyle(fontSize: 20)),
                  label: const Text('亲子报告', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onModuleTap(BuildContext context, _ModuleInfo module) {
    if (!module.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.name}训练即将上线，敬请期待！')),
      );
      return;
    }

    final profile = context.read<ChildProfileState>();
    final childData = {
      'nickname': profile.nickname,
      'age': profile.age,
    };

    Widget screen;
    switch (module.id) {
      case 'cpt':
        screen = CptScreen(childProfile: childData);
        break;
      case 'corsi':
        screen = CorsiScreen(childProfile: childData);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${module.name}训练即将上线！')),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ModuleInfo {
  final String emoji;
  final String name;
  final String subtitle;
  final Color color;
  final String id;
  final bool enabled;

  const _ModuleInfo(this.emoji, this.name, this.subtitle, this.color, this.id,
      {this.enabled = false});
}

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo info;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = info.enabled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? info.color : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                info.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.white : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey[500],
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 4),
                Text(
                  '即将上线',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

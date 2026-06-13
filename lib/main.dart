import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'core/difficulty/adaptive_difficulty.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/child_profile.dart';
import 'features/training/tasks/attention/attention_hub.dart';
import 'features/training/tasks/memory/memory_hub.dart';
import 'features/training/tasks/number_sense/number_hub.dart';
import 'features/training/tasks/reaction_speed/reaction_hub.dart';
import 'features/training/tasks/reasoning_task/reasoning_hub.dart';
import 'features/training/tasks/spatial_reasoning/spatial_hub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  await AdaptiveDifficulty.init();
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _modules = [
    _ModuleInfo('🎯', '专注', '3个游戏', Color(0xFF42A5F5), 'attention'),
    _ModuleInfo('🧠', '记忆', '3个游戏', Color(0xFFAB47BC), 'memory'),
    _ModuleInfo('🔢', '数感', '3个游戏', Color(0xFF66BB6A), 'number'),
    _ModuleInfo('⚡', '反应', '3个游戏', Color(0xFFFF7043), 'reaction'),
    _ModuleInfo('🧩', '推理', '3个游戏', Color(0xFFFFCA28), 'reasoning'),
    _ModuleInfo('🔮', '空间', '3个游戏', Color(0xFF26C6DA), 'spatial'),
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
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(profile.avatar, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(profile.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('${profile.age}岁', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              const Text('今天练什么？', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final m = _modules[index];
                    return _ModuleCard(info: m, onTap: () => _onModuleTap(context, m));
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _onModuleTap(BuildContext context, _ModuleInfo module) {
    final profile = context.read<ChildProfileState>();
    final childData = {'nickname': profile.nickname, 'age': profile.age};

    Widget hub;
    switch (module.id) {
      case 'attention': hub = AttentionHub(childProfile: childData); break;
      case 'memory': hub = MemoryHub(childProfile: childData); break;
      case 'number': hub = NumberHub(childProfile: childData); break;
      case 'reaction': hub = ReactionHub(childProfile: childData); break;
      case 'reasoning': hub = ReasoningHubScreen(childProfile: childData); break;
      case 'spatial': hub = SpatialHubScreen(childProfile: childData); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => hub));
  }
}

class _ModuleInfo {
  final String emoji, name, subtitle, id;
  final Color color;
  const _ModuleInfo(this.emoji, this.name, this.subtitle, this.color, this.id);
}

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo info;
  final VoidCallback onTap;
  const _ModuleCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: info.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: info.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(info.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(info.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(info.subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'rotate_task.dart';

class RotateScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const RotateScreen({super.key, required this.childProfile});

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  late RotateTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;
  int _trialStartMs = 0;

  @override
  void initState() {
    super.initState();
    _task = RotateTask(childAge: widget.childProfile['age'] ?? 6);
  }

  void _start() { setState(() => _isReady = false); _task.nextTrial(); _trialStartMs = DateTime.now().millisecondsSinceEpoch; }

  void _choose(int idx) {
    if (_task.isComplete || _chosenIdx != null) return;
    final correct = _task.checkAnswer(idx);
    setState(() { _chosenIdx = idx; _lastCorrect = correct; });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_task.isComplete) { _finish(); return; }
      _task.nextTrial(); _trialStartMs = DateTime.now().millisecondsSinceEpoch;
      setState(() { _chosenIdx = null; _lastCorrect = null; });
    });
  }

  void _finish() { LocalStorage.saveTrainingSession(_task.toSessionData()); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _endScreen())); }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Spacer(flex: 2), const Text('🔮', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
      const Text('转一转', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)), const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Column(children: [
          Text('上面有一个转过的图案', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)), SizedBox(height: 8),
          Text('下面找到和它一样的！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
          SizedBox(height: 8), Text('难度会慢慢增加哦', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        ])),
      const Spacer(),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)), onPressed: _start, child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，开始转转！', style: const TextStyle(fontSize: 18)))),
      const Spacer(flex: 2),
    ]))));

    return Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _task.progress, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Color(0xFF26C6DA))))), const SizedBox(width: 12), Text('${_task.trialCount}/${RotateTask.totalTrials}', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))]),
      const Spacer(),
      Column(children: [
        const Text('找到一样的：', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)), const SizedBox(height: 12),
        RotationTransition(turns: AlwaysStoppedAnimation(_task.targetRotation / 360), child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF26C6DA), width: 3)), child: Center(child: Text(_task.targetEmoji, style: const TextStyle(fontSize: 40))))),
      ]),
      const SizedBox(height: 24), Text('难度 Lv.${_task.level}', style: TextStyle(fontSize: 14, color: const Color(0xFF26C6DA).withValues(alpha: 0.7))),
      const Spacer(),
      if (_chosenIdx == null)
        GridView.count(crossAxisCount: _task.numOptions <= 4 ? 2 : 3, mainAxisSpacing: 10, crossAxisSpacing: 10, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.2,
          children: List.generate(_task.numOptions, (i) => GestureDetector(
            onTap: () => _choose(i),
            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!, width: 2)), child: Center(child: Text(_task.options[i], style: const TextStyle(fontSize: 40)))),
          )))
      else Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: (_lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Text(_lastCorrect == true ? '✅ 找到了！' : '❌ 不对哦', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed))),
      const SizedBox(height: 24),
    ]))));
  }

  Widget _endScreen() {
    final data = _task.toSessionData();
    return Scaffold(backgroundColor: const Color(0xFFFFF8E1), appBar: AppBar(title: const Text('训练完成'), backgroundColor: Colors.transparent), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('🎉', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
      Text('${widget.childProfile['nickname'] ?? '宝贝'}，空间感不错！', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      const SizedBox(height: 32),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text('答对了 ${data['correct_count']} 题', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
        const SizedBox(height: 16), _stat('总共', '${data['total_trials']} 题'), _stat('正确率', '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'), _stat('最终难度', 'Lv.${data['final_level']}'),
      ])),
      const Spacer(),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)), onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('返回首页', style: TextStyle(fontSize: 18)))),
    ]))));
  }

  Widget _stat(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
  ]));
}

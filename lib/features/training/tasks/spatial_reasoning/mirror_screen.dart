import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'mirror_task.dart';

class MirrorScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const MirrorScreen({super.key, required this.childProfile});

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  late MirrorTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  @override
  void initState() { super.initState(); _task = MirrorTask(childAge: widget.childProfile['age'] ?? 6); }

  void _start() { setState(() => _isReady = false); _task.nextTrial(); }
  void _choose(int idx) {
    if (_task.isComplete || _chosenIdx != null) return;
    final correct = _task.checkAnswer(idx);
    setState(() { _chosenIdx = idx; _lastCorrect = correct; });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_task.isComplete) { _finish(); return; }
      _task.nextTrial();
      setState(() { _chosenIdx = null; _lastCorrect = null; });
    });
  }
  void _finish() { LocalStorage.saveTrainingSession(_task.toSessionData()); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _end())); }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _ready();
    return Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _task.progress, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Color(0xFF26C6DA))))), const SizedBox(width: 12), Text('${_task.trialCount}/${MirrorTask.totalTrials}', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))]),
      const SizedBox(height: 8),
      Text('难度 Lv.${_task.level}', style: TextStyle(fontSize: 13, color: const Color(0xFF26C6DA).withValues(alpha: 0.7))),
      const Spacer(),
      // Half pattern with mirror line
      Column(children: [
        const Text('左边是半个图案', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)), const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF26C6DA), width: 2)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ...List.generate(_task.half.length, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(_task.half[i], style: const TextStyle(fontSize: 32)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('🪞', style: TextStyle(fontSize: 28))),
            ...List.generate(_task.half.length, (i) => Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('?', style: TextStyle(fontSize: 18, color: Colors.grey))))),
          ])),
      ]),
      const SizedBox(height: 12),
      const Text('镜子里翻过来是什么样？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      const Spacer(),
      if (_chosenIdx == null)
        ...List.generate(_task.numOptions, (i) {
          final parts = _task.options[i].split(' 🫸 ');
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.textPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!))),
            onPressed: () => _choose(i),
            child: Text(parts.length == 2 ? '${parts[0]}  🫸  ${parts[1]}' : _task.options[i], style: const TextStyle(fontSize: 18)),
          )));
        })
      else Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: (_lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Text(_lastCorrect == true ? '✅ 答对了！' : '❌ 不对哦', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed))),
      const SizedBox(height: 24),
    ]))));
  }

  Widget _ready() => Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Spacer(flex: 2), const Text('🪞', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
    const Text('照镜子', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)), const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Column(children: [
      Text('左边有半个图案', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)), SizedBox(height: 8),
      Text('镜子里翻过去什么样？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
      SizedBox(height: 8), Text('在下面选一个正确的', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
    ])),
    const Spacer(),
    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)), onPressed: _start, child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，开始照镜子！', style: const TextStyle(fontSize: 18)))),
    const Spacer(flex: 2),
  ]))));

  Widget _end() {
    final data = _task.toSessionData();
    return Scaffold(backgroundColor: const Color(0xFFFFF8E1), appBar: AppBar(title: const Text('训练完成'), backgroundColor: Colors.transparent), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('🎉', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
      Text('${widget.childProfile['nickname'] ?? '宝贝'}，真聪明！', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      const SizedBox(height: 32),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text('答对了 ${data['correct_count']} 次', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
        const SizedBox(height: 16), _s('总共', '${data['total_trials']} 次'), _s('正确率', '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'), _s('最终难度', 'Lv.${data['final_level']}'),
      ])),
      const Spacer(),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)), onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('返回首页', style: TextStyle(fontSize: 18)))),
    ]))));
  }

  Widget _s(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)), Text(b, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))]));
}

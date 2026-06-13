import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'blocks_task.dart';

class BlocksScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const BlocksScreen({super.key, required this.childProfile});

  @override
  State<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends State<BlocksScreen> {
  late BlocksTask _task;
  bool _isReady = true;
  bool _showTarget = true;
  bool _showResult = false;
  bool _lastCorrect = false;

  @override
  void initState() { super.initState(); _task = BlocksTask(childAge: widget.childProfile['age'] ?? 6); }

  void _start() { setState(() => _isReady = false); _newTrial(); }

  void _newTrial() { _task.nextTrial(); setState(() { _showTarget = true; _showResult = false; }); }

  void _onCellTap(int idx) {
    if (_showTarget || _showResult) return;
    final color = _task.tapCell(idx);
    if (color >= 0) {
      setState(() {});
      if (_task.checkComplete()) {
        setState(() { _showResult = true; _lastCorrect = true; });
        Future.delayed(const Duration(milliseconds: 1200), () { if (mounted) { if (_task.isComplete) _finish(); else _newTrial(); }});
      }
    }
  }

  void _showPatternDone() { setState(() => _showTarget = false); }
  void _skip() { _task.giveUp(); setState(() { _showResult = true; _lastCorrect = false; }); Future.delayed(const Duration(milliseconds: 1200), () { if (mounted) { if (_task.isComplete) _finish(); else _newTrial(); }}); }

  void _finish() { LocalStorage.saveTrainingSession(_task.toSessionData()); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _end())); }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _ready();
    return Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _task.progress, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Color(0xFF0097A7))))), const SizedBox(width: 12), Text('${_task.trialCount}/${BlocksTask.totalTrials}', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_showTarget ? '👀 记住积木的颜色和位置' : '👆 点积木，摆成刚才的样子', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text('Lv.${_task.level}', style: TextStyle(fontSize: 13, color: const Color(0xFF0097A7).withValues(alpha: 0.7))),
      ]),
      const SizedBox(height: 16),
      Expanded(child: Center(child: _grid())),
      if (_showTarget)
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7)), onPressed: _showPatternDone, child: const Text('记住了！开始摆', style: TextStyle(fontSize: 18)))))
      else if (!_showResult)
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: SizedBox(height: 44, child: OutlinedButton(onPressed: _skip, child: const Text('想不起来了'))))]))
      else
        Padding(padding: const EdgeInsets.all(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: (_lastCorrect ? AppTheme.correctGreen : AppTheme.wrongRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Text(_lastCorrect ? '✅ 一模一样！' : '❌ 差一点', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _lastCorrect ? AppTheme.correctGreen : AppTheme.wrongRed), textAlign: TextAlign.center))),
    ]))));
  }

  Widget _grid() {
    final gs = _task.gridSize;
    final size = 320.0 / gs;
    return SizedBox(width: 320, height: 320,
      child: GridView.count(crossAxisCount: gs, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: List.generate(gs * gs, (i) {
          final targetColor = _task.targetPattern[i];
          final userColor = _task.userPattern[i];
          final cellColor = _showTarget ? (targetColor >= 0 ? Color(BlocksTask.getColor(targetColor)) : Colors.grey[200]!) :
                            (userColor >= 0 ? Color(BlocksTask.getColor(userColor)) : Colors.grey[200]!);
          return GestureDetector(
            onTap: () => _onCellTap(i),
            child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!, width: 1))),
          );
        })),
    );
  }

  Widget _ready() => Scaffold(backgroundColor: const Color(0xFFE0F7FA), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Spacer(flex: 2), const Text('🧱', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
    const Text('搭积木', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)), const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Column(children: [
      Text('先记住积木的摆放', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)), SizedBox(height: 8),
      Text('然后自己搭出来', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
      SizedBox(height: 8), Text('难度增加：积木变多、颜色变多', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
    ])),
    const Spacer(),
    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7)), onPressed: _start, child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，开始搭积木！', style: const TextStyle(fontSize: 18)))),
    const Spacer(flex: 2),
  ]))));

  Widget _end() {
    final data = _task.toSessionData();
    return Scaffold(backgroundColor: const Color(0xFFFFF8E1), appBar: AppBar(title: const Text('训练完成'), backgroundColor: Colors.transparent), body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('🎉', style: TextStyle(fontSize: 64)), const SizedBox(height: 16),
      Text('${widget.childProfile['nickname'] ?? '宝贝'}，搭得不错！', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      const SizedBox(height: 32),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text('搭对了 ${data['correct_count']} 次', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
        const SizedBox(height: 16), _s('总共', '${data['total_trials']} 次'), _s('正确率', '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'), _s('最终难度', 'Lv.${data['final_level']}'),
      ])),
      const Spacer(),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7)), onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('返回首页', style: TextStyle(fontSize: 18)))),
    ]))));
  }

  Widget _s(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)), Text(b, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))]));
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'spatial_task.dart';

class SpatialScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const SpatialScreen({super.key, required this.childProfile});

  @override
  State<SpatialScreen> createState() => _SpatialScreenState();
}

class _SpatialScreenState extends State<SpatialScreen> {
  late SpatialTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _task = SpatialTask(childAge: widget.childProfile['age'] ?? 6);
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.nextTrial();
  }

  void _onChoice(int idx) {
    if (_task.isComplete || _chosenIdx != null) return;
    final correct = _task.checkAnswer(idx);
    setState(() { _chosenIdx = idx; _lastCorrect = correct; });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        if (_task.isComplete) {
          _finishTraining();
        } else {
          _task.nextTrial();
          setState(() { _chosenIdx = null; _lastCorrect = null; });
        }
      }
    });
  }

  void _finishTraining() {
    LocalStorage.saveTrainingSession(_task.toSessionData());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _buildEndScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    return _buildTrainingScreen();
  }

  Widget _buildReadyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🔮', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('转一转', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Text('上面有一个转过的图案', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
                    SizedBox(height: 8),
                    Text('找到和它一样的那个！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
                    SizedBox(height: 8),
                    Text('试试在脑子里转转看', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
                  onPressed: _startTraining,
                  child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，开始转转！', style: TextStyle(fontSize: 18)),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress, minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF26C6DA)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_task.trialCount}/${SpatialTask.totalTrials}',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),

              const Spacer(),

              // Target (rotated)
              Column(
                children: [
                  const Text('找到一样的：', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  RotationTransition(
                    turns: AlwaysStoppedAnimation(_task.targetRotation / 360),
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF26C6DA), width: 3),
                      ),
                      child: Center(child: Text(_task.targetEmoji, style: const TextStyle(fontSize: 40))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text('哪个转一下能变成一模一样的？', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),

              const Spacer(),

              // Options
              if (_chosenIdx == null)
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (i) {
                    final opt = _task.options[i];
                    return GestureDetector(
                      onTap: () => _onChoice(i),
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(opt.rotation / 360),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: Center(child: Text(opt.emoji, style: const TextStyle(fontSize: 44))),
                        ),
                      ),
                    );
                  }),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _lastCorrect == true
                        ? AppTheme.correctGreen.withValues(alpha: 0.1)
                        : AppTheme.wrongRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _lastCorrect == true ? '✅ 找到了！厉害' : '❌ 不对哦，再看看',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                            color: _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(title: const Text('训练完成'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('${widget.childProfile['nickname'] ?? '宝贝'}，空间感不错！',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('答对了 ${data['correct_count']} 题',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF26C6DA))),
                    const SizedBox(height: 16),
                    _buildStat('总共', '${data['total_trials']} 题'),
                    _buildStat('正确率', '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('返回首页', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ]),
    );
  }
}

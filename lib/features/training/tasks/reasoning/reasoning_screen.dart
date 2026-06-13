import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'reasoning_task.dart';

class ReasoningScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const ReasoningScreen({super.key, required this.childProfile});

  @override
  State<ReasoningScreen> createState() => _ReasoningScreenState();
}

class _ReasoningScreenState extends State<ReasoningScreen> {
  late ReasoningTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _task = ReasoningTask(childAge: widget.childProfile['age'] ?? 6);
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.nextTrial();
  }

  void _onChoice(int idx) {
    if (_task.isComplete || _chosenIdx != null) return;
    final correct = _task.checkAnswer(_task.options[idx]);
    setState(() {
      _chosenIdx = idx;
      _lastCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
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
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🧩', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('找规律', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Text('看看这些图案有什么规律？', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
                    SizedBox(height: 8),
                    Text('问号那里应该放什么？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFCA28))),
                    SizedBox(height: 8),
                    Text('在下面选一个正确的', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCA28), foregroundColor: AppTheme.textPrimary),
                  onPressed: _startTraining,
                  child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，来找规律！', style: TextStyle(fontSize: 18)),
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
      backgroundColor: const Color(0xFFFFF8E1),
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
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFCA28)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_task.trialCount}/${ReasoningTask.totalTrials}',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),

              const Spacer(),

              // Pattern display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _task.sequence.map((e) {
                  final isQuestion = e == '❓';
                  return Container(
                    width: 56, height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isQuestion ? AppTheme.warmOrange.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isQuestion ? AppTheme.warmOrange : Colors.grey[300]!, width: 2),
                    ),
                    child: Center(
                      child: Text(isQuestion ? '?' : e, style: TextStyle(fontSize: isQuestion ? 24 : 28)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              const Text('问号那里是什么？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),

              const Spacer(),

              // Options
              if (_chosenIdx == null)
                ...List.generate(_task.options.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        onPressed: () => _onChoice(i),
                        child: Text(_task.options[i], style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  );
                })
              else
                // Show feedback
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
                        _lastCorrect == true ? '✅ 答对了！' : '❌ 是 ${_task.correctAnswer} 哦',
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
              Text('${widget.childProfile['nickname'] ?? '宝贝'}，太厉害了！',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('答对了 ${data['correct_count']} 题',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFCA28))),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCA28), foregroundColor: AppTheme.textPrimary),
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

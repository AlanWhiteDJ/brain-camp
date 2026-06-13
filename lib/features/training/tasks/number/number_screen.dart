import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'number_task.dart';

class NumberScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const NumberScreen({super.key, required this.childProfile});

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  late NumberTask _task;
  bool _isReady = true;
  int? _chosenSide;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _task = NumberTask(childAge: widget.childProfile['age'] ?? 6);
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.nextTrial();
  }

  void _onChoice(int side) {
    if (_task.isComplete || _chosenSide != null) return;
    final correct = _task.checkAnswer(side);
    setState(() {
      _chosenSide = side;
      _lastCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (_task.isComplete) {
          _finishTraining();
        } else {
          _task.nextTrial();
          setState(() {
            _chosenSide = null;
            _lastCorrect = null;
          });
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
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🔢', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('比比看', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Text('两边都有小圆点，', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
                    SizedBox(height: 8),
                    Text('哪边更多？点一下！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    SizedBox(height: 8),
                    Text('比一比，越来越难哦', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _startTraining,
                  child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，开始比！', style: TextStyle(fontSize: 18)),
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
    final dots = _task.currentDots;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress, minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_task.trialCount}', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Question
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text('哪边更多？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ),

            const Spacer(),

            // Two panels side by side
            Row(
              children: [
                Expanded(child: _buildDotPanel(0, dots[0])),
                const SizedBox(width: 8),
                Expanded(child: _buildDotPanel(1, dots[1])),
              ],
            ),

            const Spacer(),

            // Feedback
            if (_chosenSide != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _lastCorrect == true
                        ? AppTheme.correctGreen.withValues(alpha: 0.1)
                        : AppTheme.wrongRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _lastCorrect == true ? '✅ 对啦！真聪明' : '❌ 再看一次',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                        color: _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPanel(int side, int count) {
    final highlight = _chosenSide == side;
    final correct = _task.correctSide == side;
    final showResult = _chosenSide != null;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    if (showResult && highlight) {
      bgColor = _lastCorrect == true
          ? AppTheme.correctGreen.withValues(alpha: 0.1)
          : AppTheme.wrongRed.withValues(alpha: 0.1);
      borderColor = _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed;
    } else if (showResult && correct && !highlight) {
      bgColor = AppTheme.correctGreen.withValues(alpha: 0.15);
      borderColor = AppTheme.correctGreen;
    }

    return GestureDetector(
      onTap: _chosenSide == null ? () => _onChoice(side) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(count, (_) => _buildDot()),
        ),
      ),
    );
  }

  Widget _buildDot() {
    final size = 24.0 + _random.nextDouble() * 12;
    final colors = [AppTheme.primaryGreen, AppTheme.warmOrange, AppTheme.calmBlue,
                    AppTheme.purple, AppTheme.softRed, Colors.amber, Colors.cyan];
    final color = colors[_random.nextInt(colors.length)];
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  final _random = Random();

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
              Text('${widget.childProfile['nickname'] ?? '宝贝'}，比完了！',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('答对了 ${data['correct_count']} 题',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
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

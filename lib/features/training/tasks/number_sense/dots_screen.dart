import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'dots_task.dart';

/// Dot Comparison Screen — "比比看"
/// Child sees two panels of colored dots. Pick which side has more.

class DotsScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const DotsScreen({super.key, required this.childProfile});

  @override
  State<DotsScreen> createState() => _DotsScreenState();
}

class _DotsScreenState extends State<DotsScreen> {
  late DotsTask _task;
  bool _isReady = true;
  int? _chosenSide;
  bool? _lastCorrect;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _task = DotsTask(childAge: widget.childProfile['age'] ?? 6);
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
      if (!mounted) return;
      if (_task.isComplete) {
        _finishTraining();
      } else {
        _task.nextTrial();
        setState(() {
          _chosenSide = null;
          _lastCorrect = null;
        });
      }
    });
  }

  void _finishTraining() {
    LocalStorage.saveTrainingSession(_task.toSessionData());
    if (!mounted) return;
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
      appBar: AppBar(
        title: const Text('比比看'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🔴🟢', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '比比看',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text(
                      '两边都有小圆点，',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '哪边更多？点一下！',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '比一比，越来越难哦 🧠',
                      style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                  ),
                  child: Text(
                    '${widget.childProfile['nickname'] ?? '宝贝'}，开始比！',
                    style: const TextStyle(fontSize: 18),
                  ),
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
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF66BB6A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '第${_task.trialCount}题',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Question prompt
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🤔', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    '哪边更多？点一点！',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Two dot panels side by side
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: _buildDotPanel(0, dots[0])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDotPanel(1, dots[1])),
                ],
              ),
            ),

            const Spacer(),

            // Feedback area
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lastCorrect == true ? '✅' : '❌',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastCorrect == true
                            ? '对啦！真聪明！'
                            : '不对哦，再看一次',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _lastCorrect == true
                              ? AppTheme.correctGreen
                              : AppTheme.wrongRed,
                        ),
                      ),
                    ],
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
      borderColor =
          _lastCorrect == true ? AppTheme.correctGreen : AppTheme.wrongRed;
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: count <= 20
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: List.generate(count, (_) => _buildDot()),
              )
            : _buildDenseDots(count),
      ),
    );
  }

  /// For higher dot counts, use a more compact layout with smaller dots
  Widget _buildDenseDots(int count) {
    // Arrange in a roughly square grid, filling the available space
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = (sqrt(count).ceil()).clamp(3, 7);
        final dotSize =
            ((constraints.maxWidth - (cols - 1) * 6) / cols).clamp(10.0, 24.0);
        // Make dots slightly smaller to fit
        final actualSize = dotSize * 0.75;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            count,
            (_) => _buildDot(size: actualSize),
          ),
        );
      },
    );
  }

  Widget _buildDot({double? size}) {
    final s = size ?? (20.0 + _random.nextDouble() * 14);
    final colors = const [
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF42A5F5),
      Color(0xFFAB47BC),
      Color(0xFFEF5350),
      Color(0xFFFFCA28),
      Color(0xFF26C6DA),
      Color(0xFFEC407A),
    ];
    final color = colors[_random.nextInt(colors.length)];
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    final acc = (data['accuracy'] as double) * 100;
    final stars = acc >= 90 ? '⭐⭐⭐' : acc >= 70 ? '⭐⭐' : '⭐';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(
                stars,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，比完了！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '答对了 ${data['correct_count']} 题',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStat('总共', '${data['total_trials']} 题'),
                    _buildStat(
                      '正确率',
                      '${acc.toStringAsFixed(0)}%',
                    ),
                    _buildStat('难度等级', 'Lv.${data['final_level']}'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('返回首页', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

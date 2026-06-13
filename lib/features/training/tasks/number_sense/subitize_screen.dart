import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'subitize_task.dart';

/// Subitizing Screen — "一眼看"
/// Brief flash of dots, child picks the correct count from 4 options.

class SubitizeScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const SubitizeScreen({super.key, required this.childProfile});

  @override
  State<SubitizeScreen> createState() => _SubitizeScreenState();
}

class _SubitizeScreenState extends State<SubitizeScreen>
    with SingleTickerProviderStateMixin {
  late SubitizeTask _task;
  bool _isReady = true;

  // Trial phases
  bool _isFlashing = false; // dots visible
  bool _showOptions = false; // answer choices visible
  bool _submitted = false;
  bool? _lastCorrect;

  final _random = Random();
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _task = SubitizeTask(childAge: widget.childProfile['age'] ?? 6);
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _startTrial();
  }

  void _startTrial() {
    _task.nextTrial();

    setState(() {
      _isFlashing = true;
      _showOptions = false;
      _submitted = false;
      _lastCorrect = null;
    });

    _flashController.forward(from: 0);

    // After flash duration, hide dots and show options
    final flashMs = _task.flashDurationMs;
    Future.delayed(Duration(milliseconds: flashMs), () {
      if (!mounted) return;
      setState(() {
        _isFlashing = false;
        _showOptions = true;
      });
    });
  }

  void _onChoice(int choice) {
    if (_submitted || !_showOptions) return;
    final correct = _task.checkAnswer(choice);
    setState(() {
      _submitted = true;
      _lastCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_task.isComplete) {
        _finishTraining();
      } else {
        _startTrial();
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
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text('一眼看'),
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
              const Text('👁️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '一眼看',
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
                      '圆点一闪就消失，',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '看看有几个？选一选！',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '越看越快，越来越难 👀',
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
                    backgroundColor: const Color(0xFFFF7043),
                  ),
                  child: Text(
                    '${widget.childProfile['nickname'] ?? '宝贝'}，开始看！',
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
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
                          Color(0xFFFF7043),
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
                      '第${_task.trialCount + 1}题',
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

            // Hint text
            if (!_submitted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _isFlashing
                      ? '👀 仔细看！'
                      : _showOptions
                          ? '🤔 刚才有几个小圆点？'
                          : '准备...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isFlashing
                        ? const Color(0xFFFF7043)
                        : AppTheme.textPrimary,
                  ),
                ),
              ),

            const Spacer(),

            // Dot display area
            _buildDotArea(),

            const Spacer(),

            // Answer options
            if (_showOptions && !_submitted) _buildOptions(),
            if (_showOptions && !_submitted) const SizedBox(height: 16),

            // Feedback
            if (_submitted) _buildFeedback(),
            if (_submitted) const SizedBox(height: 16),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDotArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFlashing
              ? const Color(0xFFFF7043).withValues(alpha: 0.3)
              : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: _isFlashing
            ? [
                BoxShadow(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            if (_isFlashing) {
              return CustomPaint(
                size: const Size(double.infinity, 240),
                painter: _DotsPainter(
                  positions: _task.dotPositions,
                  dotCount: _task.dotCount,
                  random: _random,
                  opacity: _flashController.value.clamp(0.0, 1.0),
                ),
              );
            }
            // After flash: show a question mark
            return Center(
              child: _submitted
                  ? CustomPaint(
                      size: const Size(double.infinity, 240),
                      painter: _DotsPainter(
                        positions: _task.dotPositions,
                        dotCount: _task.dotCount,
                        random: _random,
                        opacity: 1.0,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '❓',
                          style: TextStyle(
                            fontSize: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '几个？',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final options = _task.options;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          return GestureDetector(
            onTap: () => _onChoice(option),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$option',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7043),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedback() {
    final wasCorrect = _lastCorrect == true;
    final correctAnswer = _task.correctAnswer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: wasCorrect
            ? AppTheme.correctGreen.withValues(alpha: 0.1)
            : AppTheme.wrongRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wasCorrect ? AppTheme.correctGreen : AppTheme.wrongRed,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            wasCorrect ? '✅' : '❌',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                wasCorrect ? '太厉害了！一眼就看出来了！' : '没关系，再多练练',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: wasCorrect
                      ? AppTheme.correctGreen
                      : AppTheme.wrongRed,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '有 $correctAnswer 个小圆点',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
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
              Text(stars, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，看完了！',
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
                        color: Color(0xFFFF7043),
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

/// Custom painter that draws colored dots at specified positions
class _DotsPainter extends CustomPainter {
  final List<Offset> positions;
  final int dotCount;
  final Random random;
  final double opacity;

  _DotsPainter({
    required this.positions,
    required this.dotCount,
    required this.random,
    required this.opacity,
  });

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF26C6DA),
    Color(0xFFEC407A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < positions.length && i < dotCount; i++) {
      final pos = positions[i];
      final x = pos.dx * size.width;
      final y = pos.dy * size.height;
      final radius = 12.0 + random.nextDouble() * 14;

      final color = _colors[random.nextInt(_colors.length)];
      paint.color = color.withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.positions != positions;
  }
}

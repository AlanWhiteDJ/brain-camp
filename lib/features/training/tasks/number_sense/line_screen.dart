import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'line_task.dart';

/// Number Line Estimation Screen — "在哪呢"
/// Child sees a number line and drags a marker to where the target number belongs.

class LineScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const LineScreen({super.key, required this.childProfile});

  @override
  State<LineScreen> createState() => _LineScreenState();
}

class _LineScreenState extends State<LineScreen> {
  late LineTask _task;
  bool _isReady = true;
  bool _submitted = false;
  bool? _lastCorrect;

  // Drag state
  double _markerPosition = 0.0; // 0.0 to 1.0 (relative on line)
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _task = LineTask(childAge: widget.childProfile['age'] ?? 6);
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.nextTrial();
    setState(() {
      _markerPosition = 0.5; // start in the middle
      _submitted = false;
      _lastCorrect = null;
    });
  }

  /// Convert relative position [0..1] to absolute value on the number line
  double _positionToValue(double pos) {
    return _task.rangeMin + pos * (_task.rangeMax - _task.rangeMin);
  }

  /// Convert absolute value to relative position
  double _valueToPosition(double value) {
    final range = _task.rangeMax - _task.rangeMin;
    if (range == 0) return 0.5;
    return ((value - _task.rangeMin) / range).clamp(0.0, 1.0);
  }

  void _onDragUpdate(DragUpdateDetails details, double lineWidth) {
    if (_submitted || _task.isComplete) return;
    setState(() {
      _isDragging = true;
      _markerPosition += details.delta.dx / lineWidth;
      _markerPosition = _markerPosition.clamp(0.0, 1.0);
    });
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
  }

  void _onSubmit() {
    if (_submitted || _task.isComplete) return;
    final value = _positionToValue(_markerPosition);
    final correct = _task.submitPlacement(value);
    setState(() {
      _submitted = true;
      _lastCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_task.isComplete) {
        _finishTraining();
      } else {
        _task.nextTrial();
        setState(() {
          _markerPosition = 0.5;
          _submitted = false;
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
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('在哪呢'),
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
              const Text('📏', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '在哪呢',
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
                      '把数字拖到数轴上正确的位置！',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '拖动 🔽 标记试试看',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '越靠越准，越来越难 📐',
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
                    backgroundColor: const Color(0xFF42A5F5),
                  ),
                  child: Text(
                    '${widget.childProfile['nickname'] ?? '宝贝'}，开始找！',
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
    final target = _task.targetNumber;
    final isDecimal = target != target.roundToDouble();
    final targetStr = isDecimal ? target.toStringAsFixed(1) : target.toInt().toString();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
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
                          Color(0xFF42A5F5),
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

            const Spacer(flex: 1),

            // Target number display
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '把这个数字放到数轴上：',
                    style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF42A5F5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      targetStr,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Number line with draggable marker
            _buildNumberLine(),

            const Spacer(flex: 1),

            // Feedback
            if (_submitted)
              _buildFeedback(),

            // Submit button
            if (!_submitted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📍', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text('放在这里！', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberLine() {
    final rangeMin = _task.rangeMin;
    final rangeMax = _task.rangeMax;
    final rangeMinStr = rangeMin == rangeMin.roundToDouble()
        ? rangeMin.toInt().toString()
        : rangeMin.toStringAsFixed(1);
    final rangeMaxStr = rangeMax == rangeMax.roundToDouble()
        ? rangeMax.toInt().toString()
        : rangeMax.toStringAsFixed(1);

    // Computed current value
    final currentValue = _positionToValue(_markerPosition);
    final currentStr = currentValue == currentValue.roundToDouble()
        ? currentValue.toInt().toString()
        : currentValue.toStringAsFixed(1);

    // Correct position (shown after submission)
    final correctPosition = _submitted && !_task.isComplete
        ? _valueToPosition(_task.targetNumber)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Current value label above marker when dragging
          AnimatedOpacity(
            opacity: _isDragging || _submitted ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isDragging
                    ? const Color(0xFF42A5F5).withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _submitted ? '你放在 $currentStr' : currentStr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDragging
                      ? const Color(0xFF42A5F5)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // The number line with draggable marker
          LayoutBuilder(
            builder: (context, constraints) {
              final lineWidth = constraints.maxWidth;
              return GestureDetector(
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, lineWidth),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                onTapUp: _submitted
                    ? null
                    : (details) {
                        setState(() {
                          _markerPosition =
                              (details.localPosition.dx / lineWidth)
                                  .clamp(0.0, 1.0);
                        });
                      },
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Number line bar
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 45,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),

                      // Tick marks
                      for (int i = 0; i <= 4; i++)
                        Positioned(
                          left: (i / 4) * lineWidth - 1,
                          top: 40,
                          child: Container(
                            width: 2,
                            height: 20,
                            color: Colors.grey[400],
                          ),
                        ),

                      // Draggable marker pin
                      Positioned(
                        left: (_markerPosition * lineWidth).clamp(0.0, lineWidth) - 16,
                        top: 16,
                        child: AnimatedScale(
                          scale: _isDragging ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: GestureDetector(
                            onTap: () {},
                            child: const Text(
                              '📌',
                              style: TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                      ),

                      // Correct position indicator (shown after submission)
                      if (correctPosition != null)
                        Positioned(
                          left: (correctPosition * lineWidth).clamp(0.0, lineWidth) - 12,
                          top: 60,
                          child: const Text(
                            '✅',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Range labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rangeMinStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  rangeMaxStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final target = _task.targetNumber;
    final targetStr = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toStringAsFixed(1);
    final placed = _task.placedValue ?? 0;
    final placedStr = placed == placed.roundToDouble()
        ? placed.toInt().toString()
        : placed.toStringAsFixed(1);
    final error = (placed - target).abs();
    final errorStr = error == error.roundToDouble()
        ? error.toInt().toString()
        : error.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lastCorrect == true
              ? AppTheme.correctGreen.withValues(alpha: 0.1)
              : AppTheme.wrongRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _lastCorrect == true
                ? AppTheme.correctGreen
                : AppTheme.wrongRed,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              _lastCorrect == true ? '✅ 非常棒！位置很准！' : '🤔 差了一点点',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _lastCorrect == true
                    ? AppTheme.correctGreen
                    : AppTheme.wrongRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '正确答案是 $targetStr，你放到了 $placedStr',
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
            ),
            Text(
              '相差 $errorStr',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
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
                '${widget.childProfile['nickname'] ?? '宝贝'}，找到了！',
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
                      '答对了 ${data['correct_count']} 次',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
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

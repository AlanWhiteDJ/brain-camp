/// N-Back Training Screen (Memory Module)
/// Game 2: 回看一下
///
/// 3×3 grid of squares. One lights up each trial.
/// Child taps ✅ if current matches the one N steps back,
/// taps ❌ if not.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'nback_task.dart';

class NBackScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const NBackScreen({super.key, required this.childProfile});

  @override
  State<NBackScreen> createState() => _NBackScreenState();
}

class _NBackScreenState extends State<NBackScreen>
    with SingleTickerProviderStateMixin {
  late NBackTask _task;
  late AnimationController _pulseController;

  bool _isReady = true;
  int _highlightedPos = -1;
  bool _showingFeedback = false;
  int _feedbackPos = -1; // position to show green/red

  @override
  void initState() {
    super.initState();
    _task = NBackTask(childAge: widget.childProfile['age'] ?? 6);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _nextStimulus();
  }

  void _nextStimulus() {
    final result = _task.nextStimulus();
    setState(() {
      _highlightedPos = result.key;
      _showingFeedback = false;
    });

    // Show stimulus for configured duration
    Future.delayed(Duration(milliseconds: _task.stimulusDurationMs), () {
      if (mounted) {
        _task.finishStimulus();
        setState(() {
          _highlightedPos = -1;
        });
      }
    });
  }

  void _onResponse(bool respondedMatch) {
    if (_showingFeedback || _task.hasResponded || !_task.awaitingResponse) {
      return;
    }

    _task.respond(respondedMatch);

    setState(() {
      _showingFeedback = true;
      _feedbackPos = _task.currentPosition;
    });

    // Show feedback, then next trial or finish
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showingFeedback = false;
          _feedbackPos = -1;
        });

        if (_task.isComplete) {
          _finishTraining();
        } else {
          Future.delayed(Duration(milliseconds: _task.intervalMs), () {
            if (mounted) _nextStimulus();
          });
        }
      }
    });
  }

  void _finishTraining() {
    LocalStorage.saveTrainingSession(_task.toSessionData());
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _buildEndScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    return _buildTrainingScreen();
  }

  Widget _buildReadyScreen() {
    final nickname = widget.childProfile['nickname'] ?? '宝贝';
    final n = _task.nLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🔍', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '回看一下',
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '方块一个一个亮起来',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '如果和前面第 $n 个位置一样，就点 ✅',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.calmBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '不一样就点 ❌，要仔细看哦',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.calmBlue,
                  ),
                  onPressed: _startTraining,
                  child: Text(
                    '$nickname，准备好了！开始 ▶',
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
    final progress = _task.totalRounds > 0
        ? _task.currentTrial / _task.totalRounds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_task.currentTrial + 1} / ${_task.totalRounds}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.calmBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.calmBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_task.nLevel}-Back',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.calmBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showingFeedback)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _task.lastResponseCorrect
                            ? AppTheme.correctGreen.withValues(alpha: 0.15)
                            : AppTheme.wrongRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _task.lastResponseCorrect ? '✅ 对了！' : '❌ 再想想',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _task.lastResponseCorrect
                              ? AppTheme.correctGreen
                              : AppTheme.wrongRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.calmBlue.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.calmBlue),
                  minHeight: 8,
                ),
              ),
            ),

            const Spacer(),

            // 3×3 Grid
            SizedBox(
              width: 300,
              height: 300,
              child: _buildGrid(),
            ),

            const SizedBox(height: 32),

            // Hint text
            Text(
              _task.showingStimulus
                  ? '记住这个位置...'
                  : _task.awaitingResponse
                      ? '和前面第 ${_task.nLevel} 个一样吗？'
                      : '',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),

            const Spacer(),

            // Response buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _ResponseButton(
                      emoji: '❌',
                      label: '不一样',
                      color: AppTheme.softRed,
                      enabled: _task.awaitingResponse && !_showingFeedback,
                      onTap: () => _onResponse(false),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ResponseButton(
                      emoji: '✅',
                      label: '一样',
                      color: AppTheme.correctGreen,
                      enabled: _task.awaitingResponse && !_showingFeedback,
                      onTap: () => _onResponse(true),
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('难度',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  ...List.generate(_task.difficulty.maxLevel, (i) {
                    return Container(
                      width: 14,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _task.difficultyLevel
                            ? AppTheme.warmOrange
                            : AppTheme.warmOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text('Lv.${_task.difficultyLevel}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmOrange,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (col) {
            final i = row * 3 + col;
            final isHighlighted = _highlightedPos == i;
            final isFeedback = _showingFeedback && _feedbackPos == i;

            Color cellColor;
            if (isFeedback) {
              cellColor = _task.lastResponseCorrect
                  ? AppTheme.correctGreen
                  : AppTheme.wrongRed;
            } else if (isHighlighted) {
              cellColor = AppTheme.calmBlue;
            } else {
              cellColor = AppTheme.calmBlue.withValues(alpha: 0.1);
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted || isFeedback
                      ? cellColor
                      : AppTheme.calmBlue.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: (isHighlighted || isFeedback)
                    ? [
                        BoxShadow(
                          color: cellColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: (isHighlighted || isFeedback)
                        ? Colors.white
                        : AppTheme.calmBlue.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    final nickname = widget.childProfile['nickname'] ?? '宝贝';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('训练完成'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '$nickname，太厉害了！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${data['n_level']}-Back 完成！',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.calmBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('难度模式', '${data['n_level']}-Back'),
                    _buildStatRow('最终难度', 'Lv.${data['level']}'),
                    _buildStatRow('总共尝试', '${data['total_trials']} 次'),
                    _buildStatRow('本轮答对', '${data['correct_in_round']} / ${data['round_total']}'),
                    _buildStatRow('正确率',
                        '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.calmBlue,
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('返回首页', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: enabled ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? color : color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.white : color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

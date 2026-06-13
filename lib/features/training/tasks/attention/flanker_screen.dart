import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'flanker_task.dart';

/// Flanker Game Screen — "指方向"
/// Identify the central arrow direction while ignoring flanking arrows.

class FlankerScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const FlankerScreen({super.key, required this.childProfile});

  @override
  State<FlankerScreen> createState() => _FlankerScreenState();
}

class _FlankerScreenState extends State<FlankerScreen> {
  late FlankerTask _task;
  Timer? _trialTimer;
  int _timeRemainingMs = 0;

  bool _isReady = true;
  bool _isEnded = false;

  // Feedback
  bool _showingFeedback = false;
  String? _feedbackEmoji;
  Color? _feedbackColor;

  int _prevLevel = 3;

  @override
  void initState() {
    super.initState();
    _task = FlankerTask(childAge: widget.childProfile['age'] ?? 6);
    _prevLevel = _task.level;
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }

  // --- Phase management ---

  void _startTraining() {
    setState(() => _isReady = false);
    _startTrial();
  }

  void _startTrial() {
    if (_task.isComplete) {
      _finishTraining();
      return;
    }

    _task.startNextTrial();
    _timeRemainingMs = _task.responseWindowMs;
    _showingFeedback = false;

    _trialTimer?.cancel();
    const tickMs = 100;
    _trialTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _timeRemainingMs -= tickMs;
      if (_timeRemainingMs <= 0) {
        timer.cancel();
        _timeRemainingMs = 0;
        _task.recordTimeout();
        _showTimeoutFeedback();
      }
      setState(() {});
    });

    setState(() {});
  }

  void _onDirectionTap(ArrowDirection direction) {
    if (_showingFeedback) return;
    _trialTimer?.cancel();

    final result = _task.recordResponse(direction);

    if (result == FlankerResult.hit) {
      _showFeedback(true);
    } else if (result == FlankerResult.error) {
      _showFeedback(false);
    }
  }

  void _showFeedback(bool correct) {
    setState(() {
      _showingFeedback = true;
      _feedbackEmoji = correct ? '✅' : '❌';
      _feedbackColor = correct ? AppTheme.correctGreen : AppTheme.wrongRed;
    });

    _advanceAfterFeedback();
  }

  void _showTimeoutFeedback() {
    setState(() {
      _showingFeedback = true;
      _feedbackEmoji = '⏰';
      _feedbackColor = AppTheme.warmOrange;
    });

    _advanceAfterFeedback(delayMs: 800);
  }

  void _advanceAfterFeedback({int delayMs = 500}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;

      final newLevel = _task.level;
      if (newLevel != _prevLevel) {
        _prevLevel = newLevel;
        _task.syncDifficultyParams();
      }

      if (_task.isComplete) {
        _finishTraining();
      } else {
        _startTrial();
      }
    });
  }

  void _finishTraining() {
    _trialTimer?.cancel();
    LocalStorage.saveTrainingSession(_task.toSessionData());
    if (mounted) setState(() => _isEnded = true);
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    if (_isEnded) return _buildEndScreen();
    return _buildTrainingScreen();
  }

  // ======== READY SCREEN ========

  Widget _buildReadyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🧭', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '指方向',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFAB47BC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '难度等级 ${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAB47BC),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const _InstructionRow(
                      emoji: '👀',
                      text: '只看最中间的箭头',
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    // Demo arrows
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '← ← → ← ←',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '中间的箭头是 → 就按右边',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _InstructionRow(
                      emoji: '🤔',
                      text: '旁边的箭头可能不一样，别被骗哦',
                      color: AppTheme.warmOrange,
                    ),
                    const SizedBox(height: 16),
                    const _InstructionRow(
                      emoji: '⚡',
                      text: '想好就按，别犹豫太久',
                      color: AppTheme.calmBlue,
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
                    backgroundColor: const Color(0xFFAB47BC),
                  ),
                  onPressed: _startTraining,
                  child: Text(
                    '${widget.childProfile['nickname'] ?? '宝贝'}，准备好了！开始 ▶',
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

  // ======== TRAINING SCREEN ========

  Widget _buildTrainingScreen() {
    final level = _task.level;
    final trial = _task.currentTrial;
    final total = _task.totalTrials;
    final timeFraction =
        _task.responseWindowMs > 0
            ? _timeRemainingMs / _task.responseWindowMs
            : 0.0;
    final arrows = _task.arrows;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAB47BC).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.$level',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAB47BC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFAB47BC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$trial/$total',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Timer bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: timeFraction,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    timeFraction > 0.5
                        ? AppTheme.primaryGreen
                        : timeFraction > 0.25
                            ? AppTheme.warmOrange
                            : AppTheme.wrongRed,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Arrows display
            if (!_showingFeedback) ...[
              // Conflict type indicator (subtle)
              Text(
                _task.isCongruent ? '' : '⚠️ 注意辨别',
                style: TextStyle(
                  fontSize: 13,
                  color: _task.isCongruent
                      ? Colors.transparent
                      : AppTheme.warmOrange.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),

              // Arrow row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(arrows.length, (i) {
                    final isCenter = i == 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isCenter
                              ? const Color(0xFFAB47BC).withValues(alpha: 0.15)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isCenter
                              ? Border.all(
                                  color: const Color(0xFFAB47BC)
                                      .withValues(alpha: 0.4),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            arrows[i].emoji,
                            style: TextStyle(
                              fontSize: isCenter ? 30 : 24,
                              fontWeight:
                                  isCenter ? FontWeight.bold : FontWeight.normal,
                              color: isCenter
                                  ? const Color(0xFFAB47BC)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ] else ...[
              // Feedback overlay
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _feedbackColor!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _feedbackColor!.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _feedbackEmoji!,
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedbackEmoji == '⏰'
                          ? '时间到！正确答案是 ${_task.centerDirection == ArrowDirection.left ? "← 左" : "→ 右"}'
                          : _feedbackEmoji == '✅'
                              ? '答对了！'
                              : '正确答案是 ${_task.centerDirection == ArrowDirection.left ? "← 左" : "→ 右"}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _feedbackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Direction buttons
            if (!_showingFeedback)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  children: [
                    // LEFT button
                    Expanded(
                      child: _DirectionButton(
                        emoji: '👈',
                        label: '左边',
                        color: const Color(0xFF42A5F5),
                        onTap: () => _onDirectionTap(ArrowDirection.left),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // RIGHT button
                    Expanded(
                      child: _DirectionButton(
                        emoji: '👉',
                        label: '右边',
                        color: const Color(0xFFEF5350),
                        onTap: () => _onDirectionTap(ArrowDirection.right),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ======== END SCREEN ========

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    final acc = (data['accuracy'] as double) * 100;
    final stars = _computeStars(acc / 100);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('训练完成！'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Text(stars, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，方向感真棒！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '抑制控制训练完成 🧭',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '正确率 ${acc.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: acc >= 80
                            ? AppTheme.correctGreen
                            : acc >= 55
                                ? AppTheme.warmOrange
                                : AppTheme.wrongRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow('答对了', '${data['hits']} 次', '✅'),
                    const SizedBox(height: 10),
                    _buildStatRow('答错了', '${data['errors']} 次', '❌'),
                    const SizedBox(height: 10),
                    _buildStatRow('超时了', '${data['timeouts']} 次', '⏰'),
                    if ((data['mean_rt'] as double) > 0) ...[
                      const SizedBox(height: 10),
                      _buildStatRow(
                        '平均反应',
                        '${(data['mean_rt'] as double).toStringAsFixed(0)} ms',
                        '⏱️',
                      ),
                    ],
                    const Divider(height: 32),
                    _buildStatRow(
                      '一致情况',
                      '${((data['congruent_accuracy'] as double) * 100).toStringAsFixed(0)}%',
                      '🟢',
                    ),
                    const SizedBox(height: 10),
                    _buildStatRow(
                      '干扰情况',
                      '${((data['incongruent_accuracy'] as double) * 100).toStringAsFixed(0)}%',
                      '🔴',
                    ),
                    const SizedBox(height: 10),
                    _buildStatRow(
                      '最终等级',
                      'Lv.${data['level']}',
                      '🏆',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB47BC),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
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

  // --- Helpers ---

  Widget _buildStatRow(String label, String value, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
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
    );
  }

  String _computeStars(double accuracy) {
    if (accuracy >= 0.85) return '🌟🌟🌟';
    if (accuracy >= 0.65) return '🌟🌟';
    if (accuracy >= 0.45) return '🌟';
    return '💪';
  }
}

/// Big, chunky direction button for the Flanker game.
class _DirectionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable instruction row.
class _InstructionRow extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;
  const _InstructionRow({
    required this.emoji,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'search_task.dart';

/// Visual Search Game Screen — "火眼金睛"
/// Find the target emoji hidden in a grid of distractors.

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const SearchScreen({super.key, required this.childProfile});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late SearchTask _task;
  Timer? _roundTimer;
  int _timeRemainingMs = 0;

  bool _isReady = true;
  bool _isEnded = false;

  // Feedback state
  bool _showingFeedback = false;
  String? _feedbackEmoji;
  Color? _feedbackBg;
  int? _feedbackTargetIndex;

  // For timed progress bar animation
  late AnimationController _timerAnimCtrl;

  int _prevLevel = 3;

  @override
  void initState() {
    super.initState();
    _task = SearchTask(childAge: widget.childProfile['age'] ?? 6);
    _prevLevel = _task.level;
    _timerAnimCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _task.timeLimitMs),
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _timerAnimCtrl.dispose();
    super.dispose();
  }

  // --- Phase management ---

  void _startTraining() {
    setState(() => _isReady = false);
    _startRound();
  }

  void _startRound() {
    if (_task.isComplete) {
      _finishTraining();
      return;
    }

    _task.startNextTrial();
    _timeRemainingMs = _task.timeLimitMs;
    _showingFeedback = false;

    // Update timer animation duration (may change if level changed)
    _timerAnimCtrl.duration = Duration(milliseconds: _task.timeLimitMs);
    _timerAnimCtrl.forward(from: 0);

    // Countdown timer
    _roundTimer?.cancel();
    const tickMs = 100;
    _roundTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
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
      } else {
        // Update progress visually every tick
        setState(() {});
      }
    });

    setState(() {});
  }

  // --- User interaction ---

  void _onTapItem(int index) {
    if (_showingFeedback) return; // ignore taps during feedback
    _roundTimer?.cancel();
    _timerAnimCtrl.stop();

    final result = _task.recordResponse(index);

    if (result == SearchResult.hit) {
      _showHitFeedback(index);
    } else if (result == SearchResult.error) {
      _showErrorFeedback(index);
    }
    // alreadyResponded → ignore
  }

  void _showHitFeedback(int tappedIndex) {
    setState(() {
      _showingFeedback = true;
      _feedbackEmoji = '✅';
      _feedbackBg = AppTheme.correctGreen;
      _feedbackTargetIndex = tappedIndex;
    });

    _advanceAfterFeedback();
  }

  void _showErrorFeedback(int tappedIndex) {
    setState(() {
      _showingFeedback = true;
      _feedbackEmoji = '❌';
      _feedbackBg = AppTheme.wrongRed;
      _feedbackTargetIndex = tappedIndex;
    });

    // Flash the correct target too
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _feedbackTargetIndex = _task.targetIndex;
          _feedbackEmoji = '📍';
          _feedbackBg = AppTheme.warmOrange;
        });
      }
    });

    _advanceAfterFeedback(delayMs: 1200);
  }

  void _showTimeoutFeedback() {
    setState(() {
      _showingFeedback = true;
      _feedbackEmoji = '⏰';
      _feedbackBg = AppTheme.warmOrange;
      _feedbackTargetIndex = _task.targetIndex;
    });

    _advanceAfterFeedback(delayMs: 1000);
  }

  void _advanceAfterFeedback({int delayMs = 600}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;

      // Sync level
      final newLevel = _task.level;
      if (newLevel != _prevLevel) {
        _prevLevel = newLevel;
        _task.syncDifficultyParams();
      }

      if (_task.isComplete) {
        _finishTraining();
      } else {
        _startRound();
      }
    });
  }

  void _finishTraining() {
    _roundTimer?.cancel();
    _timerAnimCtrl.stop();
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
      backgroundColor: const Color(0xFFFFF3E0),
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
                '火眼金睛',
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
                  color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '难度等级 ${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF7043),
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
                child: const Column(
                  children: [
                    _InstructionRow(
                      emoji: '🎯',
                      text: '先看目标表情，记住它',
                      color: AppTheme.primaryGreen,
                    ),
                    SizedBox(height: 16),
                    _InstructionRow(
                      emoji: '👀',
                      text: '在人群中找到它，点它！',
                      color: AppTheme.warmOrange,
                    ),
                    SizedBox(height: 16),
                    _InstructionRow(
                      emoji: '⏱️',
                      text: '时间有限，越快越好',
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
                    backgroundColor: const Color(0xFFFF7043),
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
    final round = _task.currentRound;
    final total = _task.totalRounds;
    final timeFraction =
        _task.timeLimitMs > 0 ? _timeRemainingMs / _task.timeLimitMs : 0.0;

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
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.$level',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Round counter
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFF7043),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$round/$total',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Target preview
            if (!_showingFeedback) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '找出它 → ',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _task.targetEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

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

            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildGrid(),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final gridSize = _task.gridSize;
    final items = _task.gridItems;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final isTarget = index == _task.targetIndex;
        final isTappedWrong =
            _showingFeedback &&
            _feedbackTargetIndex == index &&
            _feedbackEmoji == '❌';
        final isHighlighted =
            _showingFeedback &&
            (_feedbackTargetIndex == index || isTarget);

        Color? bgColor;
        if (_showingFeedback && index == _task.targetIndex) {
          bgColor = AppTheme.correctGreen.withValues(alpha: 0.2);
        } else if (isTappedWrong) {
          bgColor = AppTheme.wrongRed.withValues(alpha: 0.2);
        }

        return GestureDetector(
          onTap: () => _onTapItem(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHighlighted
                    ? (_feedbackTargetIndex == _task.targetIndex
                        ? AppTheme.correctGreen
                        : AppTheme.wrongRed)
                    : Colors.grey[200]!,
                width: isHighlighted ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHighlighted
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isHighlighted ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                items[index],
                style: TextStyle(
                  fontSize: _emojiFontSize(gridSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _emojiFontSize(int gridSize) {
    switch (gridSize) {
      case 3:
        return 44;
      case 4:
        return 36;
      case 5:
        return 28;
      case 6:
        return 22;
      default:
        return 36;
    }
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
                '${widget.childProfile['nickname'] ?? '宝贝'}，火眼金睛！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '视觉搜索训练完成 🔍',
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
                    _buildStatRow('找到了', '${data['hits']} 次', '✅'),
                    const SizedBox(height: 10),
                    _buildStatRow('没找到', '${data['misses']} 次', '😢'),
                    const SizedBox(height: 10),
                    _buildStatRow('点错了', '${data['errors']} 次', '❌'),
                    if ((data['mean_rt'] as double) > 0) ...[
                      const SizedBox(height: 10),
                      _buildStatRow(
                        '平均用时',
                        '${(data['mean_rt'] as double).toStringAsFixed(0)} ms',
                        '⏱️',
                      ),
                    ],
                    const Divider(height: 32),
                    _buildStatRow('总轮数', '${data['completed_rounds']} 轮', '📊'),
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
                    backgroundColor: const Color(0xFFFF7043),
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

/// Reusable instruction row (same pattern as CPT).
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

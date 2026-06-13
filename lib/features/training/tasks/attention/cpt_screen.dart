import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'cpt_task.dart';

/// CPT Game Screen — "找小羊"
/// Go/No-Go: tap when sheep 🐑 appears, don't tap other animals.
///
/// Three phases: Ready (instructions) → Training (gameplay) → End (results).

class CptScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const CptScreen({super.key, required this.childProfile});

  @override
  State<CptScreen> createState() => _CptScreenState();
}

class _CptScreenState extends State<CptScreen> {
  late CptTask _task;
  Timer? _stimulusTimer;

  // Phase management
  bool _isReady = true;
  bool _isEnded = false;

  // Feedback overlay state
  bool _showingResult = false;
  String? _feedback;
  Color? _feedbackColor;

  // Previous level (to detect changes for UI animation)
  int _prevLevel = 3;

  @override
  void initState() {
    super.initState();
    _task = CptTask(childAge: widget.childProfile['age'] ?? 6);
    _prevLevel = _task.level;
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    super.dispose();
  }

  // --- Phase transitions ---

  void _startTraining() {
    setState(() => _isReady = false);
    _startStimulusCycle();
  }

  void _finishTraining() {
    _stimulusTimer?.cancel();
    LocalStorage.saveTrainingSession(_task.toSessionData());
    if (mounted) {
      setState(() => _isEnded = true);
    }
  }

  // --- Stimulus cycle ---

  void _startStimulusCycle() {
    if (_task.isComplete) {
      _finishTraining();
      return;
    }

    _task.startNextTrial();

    _stimulusTimer = Timer(Duration(milliseconds: _task.intervalMs), () {
      if (!mounted) return;
      if (_task.isComplete) {
        _finishTraining();
        return;
      }

      _task.recordMiss();
      _task.advanceTime(_task.intervalMs);

      // Sync difficulty params if level changed
      final newLevel = _task.level;
      if (newLevel != _prevLevel) {
        _prevLevel = newLevel;
        _task.syncDifficultyParams();
      }

      _startStimulusCycle();
      setState(() {});
    });
  }

  // --- User interaction ---

  void _onTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = _task.recordResponse(now);
    _task.advanceTime(_task.intervalMs);
    _stimulusTimer?.cancel();

    if (result == CptResponseResult.hit) {
      _flashResult(true);
    } else if (result == CptResponseResult.falseAlarm) {
      _flashResult(false);
    }
    // alreadyResponded → no feedback

    // Sync difficulty params if level changed
    final newLevel = _task.level;
    if (newLevel != _prevLevel) {
      _prevLevel = newLevel;
      _task.syncDifficultyParams();
    }

    if (_task.isComplete) {
      _finishTraining();
    } else {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_task.isComplete) {
          _startStimulusCycle();
          setState(() {});
        }
      });
    }
    setState(() {});
  }

  void _flashResult(bool correct) {
    setState(() {
      _showingResult = true;
      _feedback = correct ? '✅' : '❌';
      _feedbackColor = correct ? AppTheme.correctGreen : AppTheme.wrongRed;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showingResult = false;
          _feedback = null;
        });
      }
    });
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
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Decorative animals
              const Text('🐑 🐱 🐶 🐰', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 20),
              const Text(
                '找小羊',
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
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '难度等级 ${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF42A5F5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Instructions card
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
                      emoji: '🐑',
                      text: '看到小羊 → 立刻点击它！',
                      color: AppTheme.correctGreen,
                    ),
                    SizedBox(height: 16),
                    _InstructionRow(
                      emoji: '🐱🐶🐰',
                      text: '看到其他动物 → 不要点！',
                      color: AppTheme.wrongRed,
                    ),
                    SizedBox(height: 16),
                    _InstructionRow(
                      emoji: '⏱️',
                      text: '动物跑得很快，要专心哦',
                      color: AppTheme.warmOrange,
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
    final progress = _task.progress;
    final level = _task.level;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: progress + level + timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.$level',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Timer
                  Text(
                    _formatTime(_task.totalDurationMs - _task.elapsedMs),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Feedback or stimulus
            if (_showingResult && _feedback != null)
              _feedbackBubble(_feedback!, _feedbackColor!)
            else
              GestureDetector(
                onTap: _onTap,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_task.currentAnimal),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _task.currentAnimal,
                        style: const TextStyle(fontSize: 76),
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Bottom hint
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                '看到 🐑 就点它，别的不要点',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackBubble(String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 52)),
    );
  }

  // ======== END SCREEN ========

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    final accuracy = (data['accuracy'] as double) * 100;
    final stars = _computeStars(accuracy / 100);

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
              // Big celebration
              Text(stars, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，太厉害了！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '专注力训练完成 ⭐',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Stats card
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
                    // Accuracy headline
                    Text(
                      '正确率 ${accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: accuracy >= 80
                            ? AppTheme.correctGreen
                            : accuracy >= 55
                                ? AppTheme.warmOrange
                                : AppTheme.wrongRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow('找到小羊', '${data['hits']} 次', '🐑'),
                    const SizedBox(height: 10),
                    _buildStatRow('错过了小羊', '${data['misses']} 次', '😢'),
                    const SizedBox(height: 10),
                    _buildStatRow('认错了', '${data['false_alarms']} 次', '❌'),
                    const SizedBox(height: 10),
                    _buildStatRow('正确拒绝', '${data['correct_rejections']} 次', '✅'),
                    const SizedBox(height: 10),
                    _buildStatRow('总尝试', '${data['trial_count']} 次', '📊'),
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
                      '最终等级',
                      'Lv.${data['level']}',
                      '🏆',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Return button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
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

  String _formatTime(int ms) {
    final seconds = (ms / 1000).ceil();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _computeStars(double accuracy) {
    if (accuracy >= 0.85) return '🌟🌟🌟';
    if (accuracy >= 0.65) return '🌟🌟';
    if (accuracy >= 0.45) return '🌟';
    return '💪';
  }
}

/// Reusable instruction row for ready screen.
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

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/difficulty/adaptive_difficulty.dart';
import 'reasoning_hub.dart';
import 'pattern_task.dart';

/// Pattern Completion Screen — "找规律"
class PatternScreen extends StatefulWidget {
  const PatternScreen({super.key});

  @override
  State<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends State<PatternScreen> {
  late PatternTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
  }

  PatternTask _buildTask(Map<String, dynamic> profile) {
    final prev = LocalStorage.getSessionsForTask('reasoning_pattern');
    int startLevel = 3;
    if (prev.isNotEmpty) {
      startLevel = (prev.last['final_level'] as int?) ?? 3;
    }
    return PatternTask(
      difficulty: AdaptiveDifficulty(
        gameId: 'reasoning_pattern',
        maxLevel: 10,
        startLevel: startLevel,
      ),
    );
  }

  void _startTraining() {
    final profile = ChildProfileProvider.of(context);
    _task = _buildTask(profile);
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

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_task.isComplete) {
        _finishTraining();
      } else {
        _task.nextTrial();
        setState(() {
          _chosenIdx = null;
          _lastCorrect = null;
        });
      }
    });
  }

  Future<void> _finishTraining() async {
    await LocalStorage.saveTrainingSession(_task.toSessionData());
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

  // ─── Ready screen ─────────────────────────────────────────────────

  Widget _buildReadyScreen() {
    final nickname = ChildProfileProvider.of(context)['nickname'] ?? '宝贝';
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('🧩 找规律'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🧩', style: TextStyle(fontSize: 56))),
              ),
              const SizedBox(height: 20),
              const Text('找规律',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _instructionRow('👀', '看看这些图案有什么规律？'),
                    const SizedBox(height: 8),
                    _instructionRow('🤔', '问号那里应该放什么？'),
                    const SizedBox(height: 8),
                    _instructionRow('👇', '在选项里选一个正确的！'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startTraining,
                  child: Text('$nickname，来找规律！', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instructionRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  // ─── Training screen ──────────────────────────────────────────────

  Widget _buildTrainingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top bar: back + progress + level
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _task.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Lv.${_task.level}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text('${_task.trialCount}/${PatternTask.totalTrials}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),

              const Spacer(),

              // Pattern display — horizontal row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 12,
                children: _task.sequence.asMap().entries.map((entry) {
                  final isQuestion = entry.value == '❓';
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isQuestion ? const Color(0xFFFF9800).withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isQuestion ? const Color(0xFFFF9800) : Colors.grey[300]!,
                        width: isQuestion ? 2.5 : 1.5,
                      ),
                      boxShadow: isQuestion
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isQuestion ? '?' : entry.value,
                        style: TextStyle(
                          fontSize: isQuestion ? 26 : 28,
                          fontWeight: isQuestion ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '问号那里应该放什么？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                ),
              ),

              const Spacer(),

              // Options grid
              if (_chosenIdx == null)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(_task.options.length, (i) {
                    return _OptionButton(
                      emoji: _task.options[i],
                      onTap: () => _onChoice(i),
                    );
                  }),
                )
              else
                // Feedback
                _buildFeedback(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final correct = _lastCorrect == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: correct
            ? AppTheme.correctGreen.withValues(alpha: 0.1)
            : AppTheme.wrongRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correct ? AppTheme.correctGreen : AppTheme.wrongRed,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            correct ? '✅ 答对了！' : '❌ 答案是 ${_task.correctAnswer}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: correct ? AppTheme.correctGreen : AppTheme.wrongRed,
            ),
          ),
          if (!correct) ...[
            const SizedBox(height: 8),
            Text(
              '没关系，再来一题！',
              style: TextStyle(fontSize: 14, color: AppTheme.wrongRed.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── End screen ───────────────────────────────────────────────────

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
    final nickname = ChildProfileProvider.of(context)['nickname'] ?? '宝贝';
    final accPct = ((data['accuracy'] as double) * 100).toStringAsFixed(0);
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('训练完成'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(
                      '答对了 ${data['correct_count']} 题',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                    ),
                    const SizedBox(height: 16),
                    _buildStat('总共', '${data['total_trials']} 题'),
                    _buildStat('正确率', '$accPct%'),
                    _buildStat('最终等级', 'Lv.${data['final_level']}'),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('换一个'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _task = _buildTask(ChildProfileProvider.of(context));
                        _isReady = true;
                        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/');
                      },
                      child: const Text('再来一次'),
                    ),
                  ),
                ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

/// Single option button for pattern choices
class _OptionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _OptionButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
      ),
    );
  }
}

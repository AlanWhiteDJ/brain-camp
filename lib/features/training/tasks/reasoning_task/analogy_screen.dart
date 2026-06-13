import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/difficulty/adaptive_difficulty.dart';
import 'reasoning_hub.dart';
import 'analogy_task.dart';

/// Analogy Screen — "比一比"
class AnalogyScreen extends StatefulWidget {
  const AnalogyScreen({super.key});

  @override
  State<AnalogyScreen> createState() => _AnalogyScreenState();
}

class _AnalogyScreenState extends State<AnalogyScreen> {
  late AnalogyTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  AnalogyTask _buildTask(Map<String, dynamic> profile) {
    final prev = LocalStorage.getSessionsForTask('reasoning_analogy');
    int startLevel = 3;
    if (prev.isNotEmpty) {
      startLevel = (prev.last['final_level'] as int?) ?? 3;
    }
    return AnalogyTask(
      difficulty: AdaptiveDifficulty(
        gameId: 'reasoning_analogy',
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

    Future.delayed(const Duration(milliseconds: 1100), () {
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
        title: const Text('⚖️ 比一比'),
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
                  color: const Color(0xFFAB47BC).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 56))),
              ),
              const SizedBox(height: 20),
              const Text('比一比',
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
                    _instructionRow('👀', '看看前面两个图案的关系'),
                    const SizedBox(height: 4),
                    // Example display
                    _exampleRow(),
                    const SizedBox(height: 12),
                    _instructionRow('🤔', '后面两个也应该是一样的关系'),
                    const SizedBox(height: 8),
                    _instructionRow('👇', '选一个对的！'),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startTraining,
                  child: Text('$nickname，开始比一比！', style: const TextStyle(fontSize: 18)),
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

  Widget _exampleRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFAB47BC).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐱', style: TextStyle(fontSize: 32)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→', style: TextStyle(fontSize: 24, color: AppTheme.textSecondary)),
          ),
          const Text('🐾', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 24),
          const Text('🐶', style: TextStyle(fontSize: 32)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→', style: TextStyle(fontSize: 24, color: AppTheme.textSecondary)),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFAB47BC).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFAB47BC).withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(child: Text('?', style: TextStyle(fontSize: 22, color: Color(0xFFAB47BC)))),
          ),
        ],
      ),
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
              // Top bar
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
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFAB47BC)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAB47BC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Lv.${_task.level}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFAB47BC))),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text('${_task.trialCount}/${AnalogyTask.totalTrials}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),

              const Spacer(),

              // Analogy display: A : B :: C : ?
              _buildAnalogyDisplay(),

              const SizedBox(height: 12),

              // Relation hint
              if (_task.relationHint.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        _task.relationHint,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFFAB47BC)),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Options
              if (_chosenIdx == null)
                _buildOptions()
              else
                _buildFeedback(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalogyDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAB47BC).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: A → B
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _emojiBox(_task.emojiA, const Color(0xFF42A5F5)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text('就像', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 24),
                  ],
                ),
              ),
              _emojiBox(_task.emojiB, const Color(0xFFFF9800)),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 16),

          // Bottom row: C → ?
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _emojiBox(_task.emojiC, const Color(0xFF42A5F5)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text('那', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 24),
                  ],
                ),
              ),
              _emojiBox('❓', const Color(0xFFAB47BC), isQuestion: true),
            ],
          ),

          const SizedBox(height: 12),

          // Question text
          Text(
            '${_task.emojiA} 和 ${_task.emojiB} 的关系，\n就是 ${_task.emojiC} 和 ？的关系',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _emojiBox(String emoji, Color color, {bool isQuestion = false}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isQuestion ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isQuestion ? color : color.withValues(alpha: 0.25),
          width: isQuestion ? 3 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          isQuestion ? '❓' : emoji,
          style: TextStyle(
            fontSize: isQuestion ? 28 : 36,
            fontWeight: isQuestion ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(_task.options.length, (i) {
        return _AnalogyOption(
          emoji: _task.options[i],
          color: const Color(0xFFAB47BC),
          onTap: () => _onChoice(i),
        );
      }),
    );
  }

  Widget _buildFeedback() {
    final correct = _lastCorrect == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: correct
            ? AppTheme.correctGreen.withValues(alpha: 0.1)
            : AppTheme.wrongRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: correct ? AppTheme.correctGreen : AppTheme.wrongRed,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            correct ? '✅ 答对了！' : '❌ 应该是 ${_task.emojiD}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: correct ? AppTheme.correctGreen : AppTheme.wrongRed,
            ),
          ),
          const SizedBox(height: 8),
          if (correct)
            const Text(
              '你真聪明！',
              style: TextStyle(fontSize: 14, color: AppTheme.correctGreen),
            )
          else ...[
            // Show the correct pair
            Text(
              '${_task.emojiC} → ${_task.emojiD} 才对哦',
              style: TextStyle(fontSize: 14, color: AppTheme.wrongRed.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            const Text(
              '加油，下一题！',
              style: TextStyle(fontSize: 14, color: AppTheme.wrongRed),
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
                '$nickname，逻辑小天才！',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text('你的推理能力太强了！', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(
                      '答对了 ${data['correct_count']} 题',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAB47BC)),
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
                        backgroundColor: const Color(0xFFAB47BC),
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

/// Single option button for analogy choices
class _AnalogyOption extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _AnalogyOption({
    required this.emoji,
    required this.color,
    required this.onTap,
  });

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
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
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

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/difficulty/adaptive_difficulty.dart';
import 'reasoning_hub.dart';
import 'oddone_task.dart';

/// Odd One Out Screen — "找不同"
class OddOneScreen extends StatefulWidget {
  const OddOneScreen({super.key});

  @override
  State<OddOneScreen> createState() => _OddOneScreenState();
}

class _OddOneScreenState extends State<OddOneScreen> {
  late OddOneTask _task;
  bool _isReady = true;
  int? _chosenIdx;
  bool? _lastCorrect;

  OddOneTask _buildTask(Map<String, dynamic> profile) {
    final prev = LocalStorage.getSessionsForTask('reasoning_oddone');
    int startLevel = 3;
    if (prev.isNotEmpty) {
      startLevel = (prev.last['final_level'] as int?) ?? 3;
    }
    return OddOneTask(
      difficulty: AdaptiveDifficulty(
        gameId: 'reasoning_oddone',
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
    final correct = _task.checkAnswer(idx);
    setState(() {
      _chosenIdx = idx;
      _lastCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
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
        title: const Text('🔍 找不同'),
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
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🔍', style: TextStyle(fontSize: 56))),
              ),
              const SizedBox(height: 20),
              const Text('找不同',
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
                    _instructionRow('👀', '看看下面这些图案'),
                    const SizedBox(height: 8),
                    _instructionRow('🤔', '有几个是一样的，有一个不一样'),
                    const SizedBox(height: 8),
                    _instructionRow('👇', '把不一样的那个找出来！'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startTraining,
                  child: Text('$nickname，开始找不同！', style: const TextStyle(fontSize: 18)),
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
    final n = _task.items.length;

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
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF42A5F5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Lv.${_task.level}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF42A5F5))),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text('${_task.trialCount}/${OddOneTask.totalTrials}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),

              const Spacer(),

              // Category hint
              if (_task.categoryHint.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        _task.categoryHint,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF42A5F5)),
                      ),
                    ],
                  ),
                ),

              // Question
              const Text(
                '哪一个不一样？',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),

              // Items grid
              if (_chosenIdx == null)
                _buildItemsGrid(n)
              else
                _buildFeedbackWithGrid(n),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(int n) {
    // Determine item size: 4 items → larger, 5+ → smaller
    final itemSize = n <= 4 ? 120.0 : 100.0;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(n, (i) {
        return _OddItemButton(
          emoji: _task.items[i],
          size: itemSize,
          color: Colors.white,
          onTap: () => _onChoice(i),
        );
      }),
    );
  }

  Widget _buildFeedbackWithGrid(int n) {
    final itemSize = n <= 4 ? 120.0 : 100.0;
    final correct = _lastCorrect == true;

    return Column(
      children: [
        // Show items with correct/incorrect highlights
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(n, (i) {
            Color bgColor;
            if (i == _task.oddIndex) {
              bgColor = correct
                  ? AppTheme.correctGreen.withValues(alpha: 0.2)
                  : AppTheme.wrongRed.withValues(alpha: 0.2);
            } else if (i == _chosenIdx && !correct) {
              bgColor = AppTheme.wrongRed.withValues(alpha: 0.15);
            } else {
              bgColor = Colors.white;
            }
            return _OddItemButton(
              emoji: _task.items[i],
              size: itemSize,
              color: bgColor,
              borderColor: i == _task.oddIndex
                  ? (correct ? AppTheme.correctGreen : AppTheme.wrongRed)
                  : null,
              onTap: null,
            );
          }),
        ),

        const SizedBox(height: 16),

        // Feedback text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: correct
                ? AppTheme.correctGreen.withValues(alpha: 0.1)
                : AppTheme.wrongRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                correct ? '✅ 答对了！' : '❌ 应该选 ${_task.items[_task.oddIndex]}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: correct ? AppTheme.correctGreen : AppTheme.wrongRed,
                ),
              ),
              if (correct)
                Text(
                  '没错，${_task.items[_task.oddIndex]} 和其他的不一样！',
                  style: TextStyle(fontSize: 14, color: AppTheme.correctGreen.withValues(alpha: 0.8)),
                ),
            ],
          ),
        ),
      ],
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
                '$nickname，火眼金睛！',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text('你的观察力真棒！', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(
                      '答对了 ${data['correct_count']} 题',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF42A5F5)),
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
                        backgroundColor: const Color(0xFF42A5F5),
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

/// Single tappable item for the odd-one-out grid
class _OddItemButton extends StatelessWidget {
  final String emoji;
  final double size;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const _OddItemButton({
    required this.emoji,
    required this.size,
    required this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
              width: borderColor != null ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (borderColor ?? Colors.black).withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: size * 0.42)),
          ),
        ),
      ),
    );
  }
}

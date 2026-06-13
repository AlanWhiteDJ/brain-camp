/// Corsi Block-Tapping Screen (Memory Module)
/// Game 1: 记忆小路
///
/// Kid-friendly UI with 9 irregularly-positioned blocks.
/// Sequence is flashed, child taps back in order.
/// Adaptive difficulty adjusts span, speed, and reverse mode.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'corsi_task.dart';

class CorsiScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const CorsiScreen({super.key, required this.childProfile});

  @override
  State<CorsiScreen> createState() => _CorsiScreenState();
}

class _CorsiScreenState extends State<CorsiScreen>
    with SingleTickerProviderStateMixin {
  late CorsiTask _task;
  late AnimationController _animController;

  // Screen state
  bool _isReady = true;

  // Flash animation state
  int _flashStep = 0;

  // Response state
  final List<int> _tappedBlocks = [];
  bool _showingResult = false;
  bool _lastTrialCorrect = false;

  // Block animation states
  final List<bool> _blockHighlighted = List.filled(9, false);

  @override
  void initState() {
    super.initState();
    _task = CorsiTask(childAge: widget.childProfile['age'] ?? 6);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _startNewSpan();
  }

  void _startNewSpan() {
    final sequence = _task.generateSequence();
    _tappedBlocks.clear();
    _flashStep = 0;

    setState(() {});
    _flashNextBlock(sequence);
  }

  void _flashNextBlock(List<int> sequence) {
    if (_flashStep >= sequence.length) {
      _task.startResponsePhase();
      setState(() {});
      return;
    }

    final blockIdx = sequence[_flashStep];
    _task.advanceFlash(blockIdx);

    setState(() {
      _blockHighlighted[blockIdx] = true;
    });

    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _blockHighlighted[blockIdx] = false;
        });
      }
      Future.delayed(Duration(milliseconds: _task.flashIntervalMs), () {
        if (mounted) {
          _flashStep++;
          _flashNextBlock(sequence);
        }
      });
    });
  }

  void _onBlockTap(int blockIndex) {
    if (!_task.isResponding || _showingResult) return;

    setState(() {
      _blockHighlighted[blockIndex] = true;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _blockHighlighted[blockIndex] = false;
        });
      }
    });

    final complete = _task.recordTap(blockIndex);
    setState(() {
      _tappedBlocks.add(blockIndex);
    });

    if (complete) {
      _checkResponse();
    }
  }

  void _checkResponse() {
    final correct = _task.checkResponse();
    setState(() {
      _showingResult = true;
      _lastTrialCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showingResult = false;
        });

        if (_task.isComplete) {
          _finishTraining();
        } else {
          _startNewSpan();
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
    final reverse = _task.reverseMode;
    final span = _task.currentSpan;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🧱', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '记忆小路',
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
                      '看好了！方块会一个一个亮起来',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reverse
                          ? '然后颠倒顺序点回来！'
                          : '然后按同样的顺序点回来！',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '从 $span 个开始，越来越长哦',
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    if (reverse) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warmOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '🔀 倒序模式',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warmOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                  ),
                  onPressed: _startTraining,
                  child: Text(
                    '$nickname，记住了！开始 ▶',
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
    final flashMs = _task.flashDurationMs;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with difficulty info
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
                          _task.isShowingSequence
                              ? '记住 ${_task.currentSpan} 个'
                              : '点击 ${_task.currentSpan} 个',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.purple,
                          ),
                        ),
                      ),
                      if (_task.reverseMode) ...[
                        const SizedBox(width: 8),
                        const Text('🔀', style: TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                  if (_showingResult)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _lastTrialCorrect
                            ? AppTheme.correctGreen.withValues(alpha: 0.15)
                            : AppTheme.wrongRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _lastTrialCorrect ? '✅ 对了！' : '❌ 差一点',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _lastTrialCorrect
                              ? AppTheme.correctGreen
                              : AppTheme.wrongRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Block grid
            SizedBox(
              width: 320,
              height: 400,
              child: Stack(
                children: List.generate(9, (i) {
                  final pos = CorsiTask.blockPositions[i];
                  final highlighted = _blockHighlighted[i];
                  final tapped = _tappedBlocks.contains(i);

                  return AnimatedPositioned(
                    duration: Duration(milliseconds: flashMs),
                    left: pos.x * 320 - 30,
                    top: pos.y * 400 - 30,
                    child: GestureDetector(
                      onTap: () => _onBlockTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppTheme.warmOrange
                              : tapped
                                  ? AppTheme.purple
                                  : AppTheme.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: highlighted
                                ? AppTheme.warmOrange
                                : AppTheme.purple.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: highlighted
                              ? [
                                  BoxShadow(
                                    color: AppTheme.warmOrange
                                        .withValues(alpha: 0.4),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: highlighted || tapped
                                  ? Colors.white
                                  : AppTheme.purple.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Difficulty indicator & hints
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Column(
                children: [
                  // Level bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('难度', style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      ...List.generate(_task.maxLevel, (i) {
                        return Container(
                          width: 16,
                          height: 6,
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
                  const SizedBox(height: 12),
                  Text(
                    _task.isShowingSequence
                        ? '仔细看方块亮的顺序...'
                        : _task.isResponding
                            ? _tappedBlocks.isEmpty
                                ? '来，按${_task.reverseMode ? "倒序" : "顺序"}点回去！'
                                : '还剩 ${_task.currentSpan - _tappedBlocks.length} 个...'
                            : '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                '$nickname，今天真棒！',
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
                      '最长记住了 ${data['max_span']} 个方块！',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.purple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('最终难度', 'Lv.${data['level']}'),
                    _buildStatRow('总共尝试', '${data['total_trials']} 次'),
                    _buildStatRow('做对了', '${data['total_correct']} 次'),
                    _buildStatRow('正确率',
                        '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'),
                    if (data['reverse_mode_used'] == true)
                      _buildStatRow('倒序模式', '✅ 已开启'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
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

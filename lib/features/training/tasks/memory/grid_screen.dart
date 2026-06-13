/// Pattern Memory Grid Screen (Memory Module)
/// Game 3: 图案记忆
///
/// Kid-friendly UI showing a grid with lit-up cells.
/// Pattern is displayed briefly then hidden; child taps to reproduce it.
/// Adaptive difficulty: grid grows 2×2→5×5, display gets shorter.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'grid_task.dart';

class GridScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const GridScreen({super.key, required this.childProfile});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen>
    with SingleTickerProviderStateMixin {
  late GridTask _task;
  late AnimationController _pulseController;

  bool _isReady = true;
  bool _showingResult = false;
  bool _lastTrialCorrect = false;

  @override
  void initState() {
    super.initState();
    _task = GridTask(childAge: widget.childProfile['age'] ?? 6);
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
    _startNewPattern();
  }

  void _startNewPattern() {
    _task.generatePattern();
    setState(() {});

    // Auto-hide pattern after display time
    Future.delayed(Duration(milliseconds: _task.displayTimeMs), () {
      if (mounted) {
        _task.startResponsePhase();
        setState(() {});
      }
    });
  }

  void _onCellTap(int cellIndex) {
    if (!_task.isResponding || _showingResult) return;

    setState(() {
      _task.toggleCell(cellIndex);
    });
  }

  void _checkResult() {
    final correct = _task.checkResponse();
    setState(() {
      _showingResult = true;
      _lastTrialCorrect = correct;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showingResult = false;
        });

        if (_task.isComplete) {
          _finishTraining();
        } else {
          _startNewPattern();
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
    final size = _task.gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🟩', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '图案记忆',
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
                      '仔细看！格子里有几个方块亮起来了',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '消失后把它们一模一样地点亮！',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '从 ${size}×$size 格子开始，越来越大哦',
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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
                    backgroundColor: AppTheme.warmOrange,
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
    final size = _task.gridSize;
    final displaySeconds = (_task.displayTimeMs / 1000).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
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
                          '${size} × $size 格子',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warmOrange,
                          ),
                        ),
                      ),
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
                        _lastTrialCorrect ? '✅ 完全正确！' : '❌ 差一点点',
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

            // Grid
            _buildPatternGrid(size),

            const SizedBox(height: 24),

            // Hint / action
            if (_task.isShowingPattern) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warmOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👀 ', style: TextStyle(fontSize: 20)),
                    Text(
                      '记住图案！${displaySeconds}秒后消失',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warmOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_showingResult && _task.isResponding) ...[
              Text(
                _task.tappedCells.isEmpty
                    ? '来，把刚才看到的点亮！'
                    : '点错了可以再点一次取消',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _task.tappedCells.isNotEmpty
                      ? _checkResult
                      : null,
                  child: const Text(
                    '我好了！▶',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Difficulty indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('难度',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  ...List.generate(_task.maxLevel, (i) {
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

  Widget _buildPatternGrid(int size) {
    final target = _task.targetPattern;
    final tapped = _task.tappedCells;

    // Determine which cells light up visually
    Set<int> litCells;
    if (_task.isShowingPattern) {
      // Show the target pattern
      litCells = target;
    } else if (_showingResult) {
      // Show both target (correct answer) and user's mistakes
      litCells = {};
      // Don't auto-show during result — handled per-cell below
    } else {
      // User is responding — show what they've tapped
      litCells = tapped;
    }

    // Calculate cell size based on grid
    final maxGridWidth = 300.0;
    final cellGap = 6.0;
    final cellSize =
        (maxGridWidth - (size - 1) * cellGap) / size;

    return SizedBox(
      width: maxGridWidth,
      height: maxGridWidth,
      child: Wrap(
        spacing: cellGap,
        runSpacing: cellGap,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: List.generate(size * size, (i) {
          final isTarget = target.contains(i);
          final isTapped = tapped.contains(i);
          final isLit =
              _task.isShowingPattern ? isTarget : isTapped;

          // Determine cell color
          Color cellColor;
          if (_showingResult) {
            if (isTarget && isTapped) {
              cellColor = AppTheme.correctGreen; // correct
            } else if (isTarget && !isTapped) {
              cellColor = AppTheme.warmOrange; // missed
            } else if (!isTarget && isTapped) {
              cellColor = AppTheme.wrongRed; // extra
            } else {
              cellColor = AppTheme.warmOrange.withValues(alpha: 0.08);
            }
          } else {
            cellColor = isLit
                ? (_task.isResponding
                    ? AppTheme.primaryGreen
                    : AppTheme.warmOrange)
                : AppTheme.warmOrange.withValues(alpha: 0.08);
          }

          return GestureDetector(
            onTap: () => _onCellTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(
                    size <= 3 ? 12 : 8),
                border: Border.all(
                  color: (_showingResult && (isTarget || isTapped))
                      ? cellColor
                      : AppTheme.warmOrange.withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: isLit && !_showingResult
                    ? [
                        BoxShadow(
                          color: cellColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: _showingResult
                  ? Center(
                      child: Text(
                        isTarget && isTapped
                            ? '✅'
                            : isTarget
                                ? '🔸'
                                : isTapped
                                    ? '❌'
                                    : '',
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  : null,
            ),
          );
        }),
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
                '$nickname，记忆力真好！',
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
                      '做到了 ${data['grid_size']}×${data['grid_size']} 的格子！',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('最终难度', 'Lv.${data['level']}'),
                    _buildStatRow('总共尝试', '${data['total_trials']} 次'),
                    _buildStatRow('做对了', '${data['total_correct']} 次'),
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
                    backgroundColor: AppTheme.warmOrange,
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

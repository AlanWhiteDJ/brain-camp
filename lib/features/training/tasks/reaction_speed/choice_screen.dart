import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'choice_task.dart';

class ChoiceScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const ChoiceScreen({super.key, required this.childProfile});

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen>
    with SingleTickerProviderStateMixin {
  late ChoiceTask _task;
  Timer? _responseTimer;
  bool _isReady = true;
  ChoiceResult? _lastResult;
  int? _lastRt;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _task = ChoiceTask(childAge: widget.childProfile['age'] ?? 6);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.syncDifficultyParams();
    _nextTrial();
  }

  void _nextTrial() {
    _task.startNextTrial();
    _lastResult = null;
    _lastRt = null;

    _bounceController.reset();
    _bounceController.forward();

    // Start response window timer
    _responseTimer?.cancel();
    _responseTimer = Timer(
      Duration(milliseconds: _task.responseWindowMs),
      _onTimeout,
    );

    setState(() {});
  }

  void _onTimeout() {
    if (!mounted) return;
    _task.handleTimeout();
    setState(() => _lastResult = ChoiceResult.timeout);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_task.isComplete) {
        _task.syncDifficultyParams();
        _nextTrial();
      } else if (mounted && _task.isComplete) {
        _finishTraining();
      }
    });
  }

  void _onDirectionTap(ChoiceDirection tapped) {
    if (_task.phase != ChoicePhase.stimulus) return;

    final result = _task.tap(tapped);
    _responseTimer?.cancel();

    if (result == ChoiceResult.none) return;

    _lastRt = result == ChoiceResult.correct
        ? _task.reactionTimes.last
        : null;

    setState(() => _lastResult = result);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_task.isComplete) {
        _task.syncDifficultyParams();
        _nextTrial();
      } else if (mounted && _task.isComplete) {
        _finishTraining();
      }
    });
  }

  void _finishTraining() {
    _responseTimer?.cancel();
    LocalStorage.saveTrainingSession(_task.toSessionData());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _buildEndScreen()),
    );
  }

  Color _backgroundColor() {
    if (_lastResult == ChoiceResult.correct) {
      return AppTheme.correctGreen;
    }
    if (_lastResult == ChoiceResult.wrongDirection ||
        _lastResult == ChoiceResult.timeout) {
      return AppTheme.softRed;
    }
    return AppTheme.calmBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    return _buildTrainingScreen();
  }

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
              const Text('👈👉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '左右开弓',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _task.upEnabled
                    ? '四向反应 · 难度等级：${_task.level}/10'
                    : '左右反应 · 难度等级：${_task.level}/10',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.calmBlue,
                  fontWeight: FontWeight.w600,
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
                    const Text(
                      '箭头指向哪边，就点哪边！',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '越快越好，但是要点对哦 💪',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.calmBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _task.upEnabled
                          ? '左右上下四个方向都要注意'
                          : '先练左右两个方向',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
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
                    '${widget.childProfile['nickname'] ?? '宝贝'}，开始练！',
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
    final isStimulus = _task.phase == ChoicePhase.stimulus;
    final showFeedback = _lastResult != null;

    return Scaffold(
      backgroundColor: _backgroundColor(),
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
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_task.trialCount}/${_task.maxTrials} · Lv.${_task.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center direction indicator (during stimulus)
            if (isStimulus)
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _bounceAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _task.directionEmoji,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
              ),

            // Feedback
            if (showFeedback)
              _buildFeedback(),

            if (!isStimulus && !showFeedback)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '🤔',
                  style: TextStyle(fontSize: 64),
                ),
              ),

            const Spacer(),

            // Direction buttons
            _buildDirectionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    if (_lastResult == ChoiceResult.correct) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            '${_lastRt}ms',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '对啦！',
            style: TextStyle(fontSize: 22, color: Colors.white70),
          ),
        ],
      );
    }
    if (_lastResult == ChoiceResult.wrongDirection) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            '应该是 ${_task.directionLabel(_task.currentDirection!)} 边',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '没关系，继续加油 💪',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      );
    }
    if (_lastResult == ChoiceResult.timeout) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⏰', style: TextStyle(fontSize: 48)),
          SizedBox(height: 8),
          Text(
            '时间到！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '下次快一点哦',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildDirectionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Up button
          if (_task.upEnabled)
            _buildDirectionButton(
              ChoiceDirection.up,
              '👆',
              '上',
              const EdgeInsets.only(bottom: 8),
            ),

          // Left / Right row
          Row(
            children: [
              Expanded(
                child: _buildDirectionButton(
                  ChoiceDirection.left,
                  '👈',
                  '左',
                  const EdgeInsets.only(right: 4),
                ),
              ),
              Expanded(
                child: _buildDirectionButton(
                  ChoiceDirection.right,
                  '👉',
                  '右',
                  const EdgeInsets.only(left: 4),
                ),
              ),
            ],
          ),

          // Down button
          if (_task.downEnabled)
            _buildDirectionButton(
              ChoiceDirection.down,
              '👇',
              '下',
              const EdgeInsets.only(top: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(
    ChoiceDirection dir,
    String emoji,
    String label,
    EdgeInsets margin,
  ) {
    return Padding(
      padding: margin,
      child: GestureDetector(
        onTap: () => _onDirectionTap(dir),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndScreen() {
    final data = _task.toSessionData();
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
              const Text('🎯', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，反应很准！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.calmBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '最终等级：Lv.${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.calmBlue,
                    fontWeight: FontWeight.w600,
                  ),
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
                      '答对了 ${data['correct_count']} 题',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.calmBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStat('平均反应', '${data['mean_rt']?.toStringAsFixed(0) ?? '-'} ms'),
                    _buildStat('点错方向', '${data['wrong_direction']} 次'),
                    _buildStat('超时', '${data['timeout_count']} 次'),
                    _buildStat('总共', '${data['total_trials']} 题'),
                    _buildStat(
                      '正确率',
                      '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%',
                    ),
                    _buildStat(
                      '方向数',
                      data['num_directions'] == 4 ? '4个方向' : '2个方向',
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
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('返回首页', style: TextStyle(fontSize: 18)),
                ),
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

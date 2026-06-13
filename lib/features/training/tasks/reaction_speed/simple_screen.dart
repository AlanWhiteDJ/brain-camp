import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'simple_task.dart';

class SimpleScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const SimpleScreen({super.key, required this.childProfile});

  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen>
    with SingleTickerProviderStateMixin {
  late SimpleTask _task;
  Timer? _foreperiodTimer;
  bool _isReady = true;
  SimpleResult? _lastResult;
  int? _lastRt;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _task = SimpleTask(childAge: widget.childProfile['age'] ?? 6);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _foreperiodTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.syncDifficultyParams();
    _startTrial();
  }

  void _startTrial() {
    _task.startTrial();
    setState(() => _lastResult = null);

    _foreperiodTimer = Timer(Duration(milliseconds: _task.foreperiodMs), () {
      if (mounted && !_task.isComplete) {
        _pulseController.stop();
        setState(() => _task.showStimulus());
      }
    });
  }

  void _onTap() {
    final result = _task.tap();
    _foreperiodTimer?.cancel();

    if (result == SimpleResult.hit) {
      _lastRt = _task.reactionTimes.last;
    }
    if (result == SimpleResult.none) return;

    setState(() => _lastResult = result);

    if (_task.isComplete) {
      _finishTraining();
    } else {
      _task.syncDifficultyParams();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_task.isComplete) {
          _pulseController.repeat(reverse: true);
          _startTrial();
        }
      });
    }
  }

  void _finishTraining() {
    _foreperiodTimer?.cancel();
    LocalStorage.saveTrainingSession(_task.toSessionData());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _buildEndScreen()),
    );
  }

  Color _phaseColor() {
    switch (_task.phase) {
      case SimplePhase.waiting:
        return AppTheme.softRed;
      case SimplePhase.stimulus:
        return AppTheme.primaryGreen;
      case SimplePhase.feedback:
        return AppTheme.textSecondary;
    }
  }

  String _phaseEmoji() {
    switch (_task.phase) {
      case SimplePhase.waiting:
        return '🔴';
      case SimplePhase.stimulus:
        return '🟢';
      case SimplePhase.feedback:
        return '⚡';
    }
  }

  String _phaseText() {
    switch (_task.phase) {
      case SimplePhase.waiting:
        return '等一等...';
      case SimplePhase.stimulus:
        return '快点！';
      case SimplePhase.feedback:
        if (_lastResult == SimpleResult.hit) return '${_lastRt}ms';
        if (_lastResult == SimpleResult.early) return '早了点！等绿色再点';
        if (_lastResult == SimpleResult.anticipation) return '太快了！不算';
        return '';
    }
  }

  Widget _reactionEmoji() {
    if (_lastResult != SimpleResult.hit || _lastRt == null) return const SizedBox();
    if (_lastRt! < 300) {
      return const Text('🚀', style: TextStyle(fontSize: 48));
    } else if (_lastRt! < 500) {
      return const Text('⚡', style: TextStyle(fontSize: 48));
    } else if (_lastRt! < 800) {
      return const Text('👍', style: TextStyle(fontSize: 48));
    }
    return const Text('🐢', style: TextStyle(fontSize: 48));
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    return _buildTrainingScreen();
  }

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
              const Text('⚡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '闪电反应',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '难度等级：${_task.level}/10',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.warmOrange,
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
                child: const Column(
                  children: [
                    Text(
                      '屏幕变绿色的时候，',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '用最快的速度点一下屏幕！',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmOrange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '红色别点，等变绿了再点 ⚡',
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
                    backgroundColor: AppTheme.warmOrange,
                  ),
                  onPressed: _startTraining,
                  child: Text(
                    '${widget.childProfile['nickname'] ?? '宝贝'}，准备好了！',
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
    final isWaiting = _task.phase == SimplePhase.waiting;

    return Scaffold(
      backgroundColor: _phaseColor(),
      body: SafeArea(
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Progress bar
              Positioned(
                top: 8,
                left: 16,
                right: 16,
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
                    Text(
                      '${_task.trialCount}/${_task.maxTrials}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Level badge
              Positioned(
                top: 30,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${_task.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Center content
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    key: ValueKey('${_task.phase}_$_lastResult'),
                    children: [
                      // Phase emoji (pulsing when waiting)
                      if (isWaiting)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          ),
                          child: Text(
                            _phaseEmoji(),
                            style: const TextStyle(fontSize: 80),
                          ),
                        )
                      else
                        Text(
                          _phaseEmoji(),
                          style: const TextStyle(fontSize: 80),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _phaseText(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _task.phase == SimplePhase.stimulus
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _reactionEmoji(),
                      if (_lastResult == SimpleResult.early) ...[
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.white70,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '等绿色出现再点哦 ⏳',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                      if (_lastResult == SimpleResult.anticipation) ...[
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.speed,
                          color: Colors.white70,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '太快了！不算哦 😅',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
              const Text('⚡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，反应真快！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warmOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '最终等级：Lv.${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.warmOrange,
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
                      '平均 ${data['mean_rt']?.toStringAsFixed(0) ?? '-'} ms',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStat('最快', '${data['fastest_rt'] ?? '-'} ms'),
                    _buildStat('最慢', '${data['slowest_rt'] ?? '-'} ms'),
                    _buildStat('抢先次数', '${data['anticipations']} 次'),
                    _buildStat('提前点击', '${data['early_taps']} 次'),
                    _buildStat('完成了', '${data['total_trials']} 次'),
                    _buildStat('正确率',
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

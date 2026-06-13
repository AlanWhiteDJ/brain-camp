import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'gonogo_task.dart';

class GoNogoScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const GoNogoScreen({super.key, required this.childProfile});

  @override
  State<GoNogoScreen> createState() => _GoNogoScreenState();
}

class _GoNogoScreenState extends State<GoNogoScreen>
    with SingleTickerProviderStateMixin {
  late GoNogoTask _task;
  Timer? _stimulusTimer;
  Timer? _interTrialTimer;
  bool _isReady = true;
  GoNogoResult? _lastResult;
  int? _lastRt;
  bool _showGetReady = false;
  bool _noResponse = false;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _task = GoNogoTask(childAge: widget.childProfile['age'] ?? 6);

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    _interTrialTimer?.cancel();
    _popController.dispose();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _task.syncDifficultyParams();
    _startGetReady();
  }

  void _startGetReady() {
    setState(() {
      _showGetReady = true;
      _lastResult = null;
      _lastRt = null;
      _noResponse = false;
    });

    _interTrialTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _startTrial();
    });
  }

  void _startTrial() {
    _task.startNextTrial();
    _showGetReady = false;

    _popController.reset();
    _popController.forward();

    // Start the response window
    _stimulusTimer = Timer(
      Duration(milliseconds: _task.stimulusWindowMs),
      _onStimulusTimeout,
    );

    setState(() {});
  }

  void _onStimulusTimeout() {
    if (!mounted) return;
    _task.handleNoResponse();
    _noResponse = true;
    setState(() {});

    _endTrial();
  }

  void _onScreenTap() {
    if (_task.phase != GoNogoPhase.stimulus) return;

    final result = _task.tap();
    if (result == GoNogoResult.none) return;

    _stimulusTimer?.cancel();
    _lastRt = result == GoNogoResult.hit ? _task.reactionTimes.last : null;
    setState(() => _lastResult = result);

    _endTrial();
  }

  void _endTrial() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_task.isComplete) {
        _task.syncDifficultyParams();
        _startGetReady();
      } else if (mounted && _task.isComplete) {
        _finishTraining();
      }
    });
  }

  void _finishTraining() {
    _stimulusTimer?.cancel();
    _interTrialTimer?.cancel();
    LocalStorage.saveTrainingSession(_task.toSessionData());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _buildEndScreen()),
    );
  }

  Color _backgroundColor() {
    if (_task.phase != GoNogoPhase.stimulus) {
      if (_lastResult == GoNogoResult.hit) return AppTheme.correctGreen;
      if (_lastResult == GoNogoResult.falseAlarm) return AppTheme.softRed;
      if (_noResponse) {
        if (_task.isGo) return AppTheme.softRed; // missed a go
        return AppTheme.correctGreen; // correctly stopped
      }
      return const Color(0xFFF5F5F5);
    }
    // During stimulus: neutral background
    return const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return _buildReadyScreen();
    return _buildTrainingScreen();
  }

  Widget _buildReadyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text('🟢🔴', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '绿灯行',
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
                  color: AppTheme.primaryGreen,
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
                      '🟢 绿灯亮了 → 快点屏幕！',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '🔴 红灯亮了 → 不要动！',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softRed,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '管住小手，忍住不点哦 ✋',
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
                    backgroundColor: AppTheme.primaryGreen,
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
    return Scaffold(
      backgroundColor: _backgroundColor(),
      body: SafeArea(
        child: GestureDetector(
          onTap: _onScreenTap,
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
                          backgroundColor: Colors.black.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            _task.isGo
                                ? AppTheme.primaryGreen
                                : AppTheme.softRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_task.trialCount}/${_task.maxTrials} · Lv.${_task.level}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Center content
              Center(child: _buildCenterContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    // Get ready phase
    if (_showGetReady) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '👀',
            style: TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 12),
          Text(
            '准备...',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    // Feedback phase
    if (_task.phase == GoNogoPhase.feedback || _lastResult != null) {
      return _buildFeedback();
    }

    // Stimulus phase
    if (_task.phase == GoNogoPhase.stimulus) {
      return _buildStimulus();
    }

    return const SizedBox();
  }

  Widget _buildStimulus() {
    final isGo = _task.isGo;
    final color = isGo ? AppTheme.primaryGreen : AppTheme.softRed;
    final emoji = isGo ? '🟢' : '🔴';

    return AnimatedBuilder(
      animation: _popAnimation,
      builder: (context, child) => Transform.scale(
        scale: _popAnimation.value,
        child: child,
      ),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 72),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    // Tapped correctly on go
    if (_lastResult == GoNogoResult.hit) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            '${_lastRt}ms',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '反应真快！⚡',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      );
    }

    // Tapped on red (false alarm)
    if (_lastResult == GoNogoResult.falseAlarm) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❌', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.softRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '红灯不能点！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.softRed,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '忍住哦 ✋',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // No response feedback
    if (_noResponse) {
      if (_task.isGo) {
        // Missed a go signal
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😴', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    '绿灯亮了！错过了',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warmOrange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '下次快点哦 ⏰',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        // Correctly stopped on red
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.correctGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    '忍住啦！',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.correctGreen,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '管住小手真棒 👏',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox();
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
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，真会管住自己！',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '最终等级：Lv.${_task.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryGreen,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniStat('🟢 对点', '${data['hits']}'),
                        _buildMiniStat('🔴 忍对', '${data['correct_rejections']}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniStat('⏰ 漏点', '${data['misses']}'),
                        _buildMiniStat('❌ 误点', '${data['false_alarms']}'),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildStat('平均反应', '${data['mean_rt']?.toStringAsFixed(0) ?? '-'} ms'),
                    _buildStat(
                      '正确率',
                      '${((data['overall_accuracy'] as double) * 100).toStringAsFixed(0)}%',
                    ),
                    _buildStat(
                      'Go/No-Go',
                      '${data['go_count']}/${data['no_go_count']}',
                    ),
                    _buildStat('信号检测力', '${data['d_prime']?.toStringAsFixed(2) ?? '-'}'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
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

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
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

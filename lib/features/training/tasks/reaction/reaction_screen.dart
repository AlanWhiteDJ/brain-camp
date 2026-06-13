import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'reaction_task.dart';

class ReactionScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const ReactionScreen({super.key, required this.childProfile});

  @override
  State<ReactionScreen> createState() => _ReactionScreenState();
}

class _ReactionScreenState extends State<ReactionScreen> {
  late ReactionTask _task;
  Timer? _foreperiodTimer;
  bool _isReady = true;
  ReactionResult? _lastResult;
  int? _lastRt;

  @override
  void initState() {
    super.initState();
    _task = ReactionTask(childAge: widget.childProfile['age'] ?? 6);
  }

  @override
  void dispose() {
    _foreperiodTimer?.cancel();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _startTrial();
  }

  void _startTrial() {
    _task.startTrial();
    setState(() => _lastResult = null);

    _foreperiodTimer = Timer(Duration(milliseconds: _task.foreperiodMs), () {
      if (mounted && !_task.isComplete) {
        setState(() => _task.showStimulus());
      }
    });
  }

  void _onTap() {
    final result = _task.tap();
    _foreperiodTimer?.cancel();

    if (result == ReactionResult.hit) {
      _lastRt = _task.reactionTimes.last;
    }

    setState(() => _lastResult = result);

    // Brief feedback then next trial
    if (_task.isComplete) {
      _finishTraining();
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_task.isComplete) _startTrial();
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
      case ReactionPhase.waiting: return AppTheme.softRed;
      case ReactionPhase.stimulus: return AppTheme.primaryGreen;
      case ReactionPhase.feedback: return AppTheme.textSecondary;
    }
  }

  String _phaseText() {
    switch (_task.phase) {
      case ReactionPhase.waiting: return '等一等...';
      case ReactionPhase.stimulus: return '快点！';
      case ReactionPhase.feedback:
        if (_lastResult == ReactionResult.hit) return '${_lastRt}ms';
        if (_lastResult == ReactionResult.early) return '早了点！等绿色再点';
        if (_lastResult == ReactionResult.anticipation) return '太快了！不算';
        return '';
    }
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
              const Text('闪电反应',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Text('红色变绿色的时候，', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
                    SizedBox(height: 8),
                    Text('用最快的速度点一下屏幕！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.warmOrange)),
                    SizedBox(height: 8),
                    Text('红色别点，等绿了再点', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warmOrange),
                  onPressed: _startTraining,
                  child: Text('${widget.childProfile['nickname'] ?? '宝贝'}，准备好了！', style: TextStyle(fontSize: 18)),
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
      backgroundColor: _phaseColor(),
      body: SafeArea(
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Progress
              Positioned(
                top: 8, left: 16, right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _task.progress, minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_task.trialCount}/${ReactionTask.maxTrials}',
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),

              // Center feedback
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    key: ValueKey('${_task.phase}_$_lastResult'),
                    children: [
                      Text(
                        _phaseText(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _task.phase == ReactionPhase.stimulus ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (_lastResult == ReactionResult.hit) ...[
                        const SizedBox(height: 12),
                        Icon(
                          _lastRt != null && _lastRt! < 400 ? Icons.bolt : Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                      ],
                      if (_lastResult == ReactionResult.early) ...[
                        const SizedBox(height: 12),
                        const Icon(Icons.warning_amber, color: Colors.white70, size: 36),
                        const SizedBox(height: 8),
                        const Text('等绿色出现再点哦', style: TextStyle(fontSize: 18, color: Colors.white70)),
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
      appBar: AppBar(title: const Text('训练完成'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('${widget.childProfile['nickname'] ?? '宝贝'}，反应真快！',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('平均 ${data['mean_rt']?.toStringAsFixed(0) ?? '-'} ms',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.warmOrange)),
                    const SizedBox(height: 16),
                    _buildStat('最快', '${(_task.reactionTimes.isNotEmpty ? _task.reactionTimes.reduce((a,b)=>a<b?a:b) : '-')} ms'),
                    _buildStat('抢先次数', '${data['anticipations']} 次'),
                    _buildStat('完成了', '${data['total_trials']} 次'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warmOrange),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ]),
    );
  }
}

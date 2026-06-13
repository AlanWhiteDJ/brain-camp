import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import 'cpt_task.dart';

class CptScreen extends StatefulWidget {
  final Map<String, dynamic> childProfile;
  const CptScreen({super.key, required this.childProfile});

  @override
  State<CptScreen> createState() => _CptScreenState();
}

class _CptScreenState extends State<CptScreen> {
  late CptTask _task;
  Timer? _stimulusTimer;

  // Screen state
  bool _isReady = true;
  bool _showingResult = false;
  String? _feedback;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _task = CptTask(
      childAge: widget.childProfile['age'] ?? 6,
    );
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    super.dispose();
  }

  void _startTraining() {
    setState(() => _isReady = false);
    _startStimulusCycle();
  }

  void _startStimulusCycle() {
    _task.startNextTrial();

    // Show stimulus for a fixed duration, then check for miss
    _stimulusTimer = Timer(Duration(milliseconds: _task.intervalMs), () {
      if (mounted && !_task.isComplete) {
        _task.recordMiss();
        _task.advanceTime(_task.intervalMs);

        // Adjust difficulty every 20 trials
        if (_task.trialCount % 20 == 0) {
          _task.adjustDifficulty();
        }

        if (_task.isComplete) {
          _finishTraining();
        } else {
          _startStimulusCycle();
        }
        setState(() {});
      }
    });
  }

  void _onTap() {
    if (!_task.isTarget) {
      // Tapped on distractor: false alarm
      final now = DateTime.now().millisecondsSinceEpoch;
      _task.recordResponse(now);
      _task.advanceTime(_task.intervalMs);
      _flashResult(false);
    } else {
      // Tapped on target: hit
      final now = DateTime.now().millisecondsSinceEpoch;
      _task.recordResponse(now);
      _task.advanceTime(_task.intervalMs);
      _flashResult(true);
    }

    _stimulusTimer?.cancel();

    if (_task.isComplete) {
      _finishTraining();
    } else {
      // Brief pause then next stimulus
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

  void _finishTraining() {
    _stimulusTimer?.cancel();

    // Save session
    LocalStorage.saveTrainingSession(_task.toSessionData());

    // Navigate to report
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _buildReportScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return _buildReadyScreen();
    }
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
              const Text('🎯', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '找小羊',
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
                      '小动物们要一个接一个跑出来了！',
                      style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '看到 🐑 小羊就点它',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '看到别的动物就不要动哦',
                      style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
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

  Widget _buildTrainingScreen() {
    final progress = _task.progress;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(_task.totalDurationMs - _task.elapsedMs),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Feedback overlay
            if (_showingResult && _feedback != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _feedbackColor!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _feedback!,
                  style: TextStyle(fontSize: 48),
                ),
              )
            else
              // Stimulus display area
              GestureDetector(
                onTap: _onTap,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_task.currentAnimal),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _task.currentAnimal,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Hint text
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '看到小羊就点它，别的不要点',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportScreen() {
    // This will be replaced by the full ReportScreen later
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
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '${widget.childProfile['nickname'] ?? '宝贝'}，今天真棒！',
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
                    _buildStatRow('找到了小羊', '${data['hits']} 次'),
                    _buildStatRow('没注意到小羊', '${data['misses']} 次'),
                    _buildStatRow('认错了小羊', '${data['false_alarms']} 次'),
                    const Divider(),
                    _buildStatRow('正确率', '${((data['accuracy'] as double) * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
              const Spacer(),
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
          Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).ceil();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

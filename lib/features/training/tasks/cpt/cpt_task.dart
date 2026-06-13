import 'dart:math';
import '../../../../core/utils/constants.dart';

/// CPT Training task - Continuous Performance Task / SART
/// Target: sheep 🐑, distractors: other animals
/// Measures sustained attention and response inhibition

class CptTask {
  final int childAge;
  final Random _random = Random();

  // Configuration
  late int _totalDurationMs;
  late int _intervalMs;
  late double _targetProb;

  // State
  int _trialCount = 0;
  int _elapsedMs = 0;

  // Metrics
  final List<int> _reactionTimes = [];
  int _hits = 0;
  int _misses = 0;
  int _falseAlarms = 0;
  int _correctRejections = 0;
  int _targetCount = 0;
  int _distractorCount = 0;

  // Current trial
  String _currentAnimal = '';
  bool _isTarget = false;
  int _trialStartMs = 0;
  bool _responded = false;

  CptTask({required this.childAge}) {
    final durationMin = TrainingConstants.trainingDurationForAge(childAge);
    _totalDurationMs = durationMin * 60000;
    _intervalMs = TrainingConstants.cptDefaultIntervalMs;
    _targetProb = TrainingConstants.cptTargetProbability;
  }

  // Getters for UI
  int get intervalMs => _intervalMs;

  int get totalDurationMs => _totalDurationMs;
  int get elapsedMs => _elapsedMs;
  double get progress => _elapsedMs / _totalDurationMs;
  bool get isComplete => _elapsedMs >= _totalDurationMs;
  String get currentAnimal => _currentAnimal;
  bool get isTarget => _isTarget;
  List<int> get reactionTimes => List.unmodifiable(_reactionTimes);

  int get hits => _hits;
  int get misses => _misses;
  int get falseAlarms => _falseAlarms;
  int get correctRejections => _correctRejections;
  int get trialCount => _trialCount;

  double get accuracy =>
      _targetCount > 0 ? _hits / _targetCount : 0;

  double get falseAlarmRate =>
      _distractorCount > 0 ? _falseAlarms / _distractorCount : 0;

  double get dPrime {
    if (_targetCount == 0 || _distractorCount == 0) return 0;
    final hitRate = (_hits / _targetCount).clamp(0.01, 0.99);
    final faRate = (_falseAlarms / _distractorCount).clamp(0.01, 0.99);
    return _normInv(hitRate) - _normInv(faRate);
  }

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  // Generate next trial
  void startNextTrial() {
    if (isComplete) return;

    _trialCount++;
    _isTarget = _random.nextDouble() < _targetProb;
    _currentAnimal = _isTarget
        ? cptTargetAnimal
        : cptAnimals[_random.nextInt(cptAnimals.length)];

    if (_isTarget) {
      _targetCount++;
    } else {
      _distractorCount++;
    }

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
    _responded = false;
  }

  // Record response (tap)
  CptResponseResult recordResponse(int responseTimeMs) {
    if (_responded) return CptResponseResult.alreadyResponded;
    _responded = true;

    final rt = responseTimeMs - _trialStartMs;
    if (_isTarget) {
      _hits++;
      _reactionTimes.add(rt);
      return CptResponseResult.hit;
    } else {
      _falseAlarms++;
      return CptResponseResult.falseAlarm;
    }
  }

  // Record missed target (no response when target was shown)
  void recordMiss() {
    if (_responded) return;
    if (_isTarget) {
      _misses++;
    } else {
      _correctRejections++;
    }
    _responded = true;
  }

  // Advance time (called when interval expires)
  void advanceTime(int ms) {
    _elapsedMs += ms;
  }

  // Adjust difficulty based on performance
  void adjustDifficulty() {
    // After every 10 targets, adjust
    final recentAccuracy = _targetCount >= 10 ? accuracy : null;

    if (recentAccuracy != null) {
      if (recentAccuracy > 0.85 && falseAlarmRate < 0.05) {
        // Too easy: speed up, reduce target probability
        _intervalMs = max(800, _intervalMs - 100);
        _targetProb = max(0.12, _targetProb - 0.02);
      } else if (recentAccuracy < 0.60 || falseAlarmRate > 0.25) {
        // Too hard: slow down, increase target probability
        _intervalMs = min(2000, _intervalMs + 100);
        _targetProb = min(0.30, _targetProb + 0.02);
      }
    }
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'cpt',
        'timestamp': DateTime.now().toIso8601String(),
        'duration_ms': _elapsedMs,
        'trial_count': _trialCount,
        'hits': _hits,
        'misses': _misses,
        'false_alarms': _falseAlarms,
        'correct_rejections': _correctRejections,
        'accuracy': accuracy,
        'false_alarm_rate': falseAlarmRate,
        'd_prime': dPrime,
        'mean_rt': meanReactionTime,
        'interval_ms': _intervalMs,
        'target_prob': _targetProb,
      };

  // Approximation of inverse normal CDF
  static double _normInv(double p) {
    // Abramowitz and Stegun approximation
    final a = <double>[2.506628, -18.615001, 41.391197, -25.441060];
    final b = <double>[-8.473511, 23.083367, -21.062241, 3.130829];
    final c = <double>[
      0.3374755, 0.9761690, 0.1607979,
      0.0276439, 0.00384057, 0.00039519, 0.00003220
    ];
    final y = p - 0.5;
    if (y.abs() < 0.42) {
      var r = y * y;
      return y *
          (((a[3] * r + a[2]) * r + a[1]) * r + a[0]) /
          ((((b[3] * r + b[2]) * r + b[1]) * r + b[0]) * r + 1);
    }
    final r = y < 0 ? p : 1 - p;
    var s = sqrt(-log(r));
    var z = (((c[6] * s + c[5]) * s + c[4]) * s + c[3]) * s +
        c[2] * s + c[1] * s + c[0];
    return y < 0 ? -z : z;
  }
}

enum CptResponseResult {
  hit,
  falseAlarm,
  alreadyResponded,
}

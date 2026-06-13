import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Go/No-Go Reaction Task — "绿灯行" 🟢
///
/// A circle appears — green means GO (tap), red means NO-GO (don't tap).
/// Tests inhibition control alongside reaction speed.
///
/// Difficulty: higher levels → shorter stimulus window, higher go ratio
/// (more go trials = harder to inhibit on rare no-go trials).

class GoNogoTask {
  final int childAge;
  final Random _random = Random();

  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters ---
  late int _stimulusWindowMs;
  late double _goProbability;
  late int maxTrials;

  // --- State ---
  int _trialCount = 0;
  bool _isComplete = false;
  GoNogoPhase _phase = GoNogoPhase.waiting;
  bool _isGo = false;
  int _stimulusOnMs = 0;
  bool _responded = false;

  // --- Metrics ---
  final List<int> _reactionTimes = [];
  int _hits = 0;       // Tapped on go → correct
  int _misses = 0;     // Didn't tap on go → wrong
  int _falseAlarms = 0; // Tapped on no-go → wrong
  int _correctRejections = 0; // Didn't tap on no-go → correct
  int _goCount = 0;
  int _noGoCount = 0;

  GoNogoTask({
    required this.childAge,
    int startLevel = 50,
  }) : _difficulty = AdaptiveDifficulty(
         gameId: 'reaction_gonogo',
         maxLevel: 255,
         startLevel: startLevel,
       ) {
    _applyLevelParams();
  }

  // --- Getters ---

  int get level => _difficulty.level;
  int get stimulusWindowMs => _stimulusWindowMs;
  int get trialCount => _trialCount;
  bool get isComplete => _isComplete;
  GoNogoPhase get phase => _phase;
  bool get isGo => _isGo;
  double get goProbability => _goProbability;
  double get progress => maxTrials > 0 ? _trialCount / maxTrials : 0;

  List<int> get reactionTimes => List.unmodifiable(_reactionTimes);
  int get hits => _hits;
  int get misses => _misses;
  int get falseAlarms => _falseAlarms;
  int get correctRejections => _correctRejections;
  int get goCount => _goCount;
  int get noGoCount => _noGoCount;

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  double get hitRate {
    if (_goCount == 0) return 0;
    return _hits / _goCount;
  }

  double get falseAlarmRate {
    if (_noGoCount == 0) return 0;
    return _falseAlarms / _noGoCount;
  }

  double get overallAccuracy {
    final correct = _hits + _correctRejections;
    final total = _goCount + _noGoCount;
    if (total == 0) return 0;
    return correct / total;
  }

  /// Signal detection d'
  double get dPrime {
    if (_goCount == 0 || _noGoCount == 0) return 0;
    final hr = hitRate.clamp(0.01, 0.99);
    final far = falseAlarmRate.clamp(0.01, 0.99);
    return _normInv(hr) - _normInv(far);
  }

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;

    // Stimulus window: shorter at higher levels (harder to decide)
    _stimulusWindowMs = DifficultyParams.inverseInt(lvl, 10, 500, 1500);

    // Go probability: higher at higher levels
    // → more go trials make the rare no-go trials harder to inhibit
    _goProbability = DifficultyParams.levelToDouble(lvl, 10, 0.55, 0.78);

    // Trials: more at higher levels
    maxTrials = DifficultyParams.levelToInt(lvl, 10, 16, 30);
  }

  // --- Trial lifecycle ---

  void startNextTrial() {
    if (_isComplete) return;
    _isGo = _random.nextDouble() < _goProbability;
    if (_isGo) {
      _goCount++;
    } else {
      _noGoCount++;
    }

    _phase = GoNogoPhase.stimulus;
    _stimulusOnMs = DateTime.now().millisecondsSinceEpoch;
    _responded = false;
  }

  GoNogoResult tap() {
    if (_phase != GoNogoPhase.stimulus || _responded) {
      return GoNogoResult.none;
    }

    _responded = true;
    final rt = DateTime.now().millisecondsSinceEpoch - _stimulusOnMs;

    if (_isGo) {
      _hits++;
      _reactionTimes.add(rt);
      _phase = GoNogoPhase.feedback;
      _trialCount++;
      final fast = rt <= _stimulusWindowMs * 0.5;
      _difficulty.recordResult(fast);
      if (_trialCount >= maxTrials) _isComplete = true;
      return GoNogoResult.hit;
    } else {
      _falseAlarms++;
      _phase = GoNogoPhase.feedback;
      _difficulty.recordResult(false);
      return GoNogoResult.falseAlarm;
    }
  }

  void handleNoResponse() {
    if (_responded) return;
    _responded = true;
    _phase = GoNogoPhase.feedback;

    if (_isGo) {
      _misses++;
      _difficulty.recordResult(false);
    } else {
      _correctRejections++;
      _difficulty.recordResult(true);
    }

    _trialCount++;
    if (_trialCount >= maxTrials) _isComplete = true;
  }

  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reaction_gonogo',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'go_count': _goCount,
        'no_go_count': _noGoCount,
        'hits': _hits,
        'misses': _misses,
        'false_alarms': _falseAlarms,
        'correct_rejections': _correctRejections,
        'hit_rate': hitRate,
        'false_alarm_rate': falseAlarmRate,
        'overall_accuracy': overallAccuracy,
        'd_prime': dPrime,
        'mean_rt': meanReactionTime,
        'level': _difficulty.level,
        'stimulus_window_ms': _stimulusWindowMs,
        'go_probability': _goProbability,
        'child_age': childAge,
        'difficulty': _difficulty.toJson(),
        'reaction_times': _reactionTimes,
      };

  // --- Helpers ---

  /// Approximation of inverse normal CDF (Abramowitz & Stegun)
  static double _normInv(double p) {
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

enum GoNogoPhase { waiting, stimulus, feedback }
enum GoNogoResult { hit, falseAlarm, none }

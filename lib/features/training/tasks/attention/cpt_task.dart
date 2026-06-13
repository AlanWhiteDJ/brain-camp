import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// CPT (Continuous Performance Task) — "找小羊"
/// Go/No-Go task: tap when you see a sheep 🐑, don't tap other animals.
///
/// Difficulty: as level increases, the stimulus interval shortens
/// and the target appears less frequently.

// Animals used in CPT
const List<String> _cptAnimals = ['🐱', '🐶', '🐰', '🐻', '🦊', '🐸', '🐵', '🐮'];
const String _cptTargetAnimal = '🐑';

class CptTask {
  final int childAge;
  final Random _random = Random();

  /// Adaptive difficulty engine
  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters (updated when level changes) ---
  late int _intervalMs;
  late double _targetProb;

  // --- State ---
  int _trialCount = 0;
  late int _totalDurationMs;
  int _elapsedMs = 0;

  // --- Metrics ---
  final List<int> _reactionTimes = [];
  int _hits = 0;
  int _misses = 0;
  int _falseAlarms = 0;
  int _correctRejections = 0;
  int _targetCount = 0;
  int _distractorCount = 0;

  // --- Current trial ---
  String _currentAnimal = '';
  bool _isTarget = false;
  int _trialStartMs = 0;
  bool _responded = false;

  CptTask({
    required this.childAge,
    int startLevel = 50,
  }) : _difficulty = AdaptiveDifficulty(
         gameId: 'attention_cpt',
         maxLevel: 255,
         upThreshold: 0.80,
         downThreshold: 0.55,
         windowSize: 12,
         startLevel: startLevel,
       ) {
    _totalDurationMs = _durationForAge(childAge) * 60000;
    _applyLevelParams();
  }

  // --- Getters ---

  int get level => _difficulty.level;
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
  int get targetCount => _targetCount;
  int get distractorCount => _distractorCount;

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

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;
    // Higher level → shorter interval (harder, must react faster)
    _intervalMs = DifficultyParams.inverseInt(lvl, 10, 800, 2000);
    // Higher level → lower target probability (rarer targets = harder to stay alert)
    _targetProb = DifficultyParams.inverseDouble(lvl, 10, 0.12, 0.25);
  }

  // --- Trial lifecycle ---

  /// Generate and show the next stimulus
  void startNextTrial() {
    if (isComplete) return;

    _trialCount++;
    _isTarget = _random.nextDouble() < _targetProb;
    _currentAnimal = _isTarget
        ? _cptTargetAnimal
        : _cptAnimals[_random.nextInt(_cptAnimals.length)];

    if (_isTarget) {
      _targetCount++;
    } else {
      _distractorCount++;
    }

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
    _responded = false;
  }

  /// User tapped the screen
  CptResponseResult recordResponse(int responseTimeMs) {
    if (_responded) return CptResponseResult.alreadyResponded;
    _responded = true;

    final rt = responseTimeMs - _trialStartMs;
    if (_isTarget) {
      _hits++;
      _reactionTimes.add(rt);
      _difficulty.recordResult(true);
      return CptResponseResult.hit;
    } else {
      _falseAlarms++;
      _difficulty.recordResult(false);
      return CptResponseResult.falseAlarm;
    }
  }

  /// Trial expired without user tapping
  void recordMiss() {
    if (_responded) return;
    if (_isTarget) {
      _misses++;
      _difficulty.recordResult(false);
    } else {
      _correctRejections++;
      _difficulty.recordResult(true);
    }
    _responded = true;
  }

  /// Advance elapsed time
  void advanceTime(int ms) {
    _elapsedMs += ms;
  }

  /// Call after recording a result — re-read level and update params
  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data for persistence ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'attention_cpt',
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
        'level': _difficulty.level,
        'interval_ms': _intervalMs,
        'target_prob': _targetProb,
        'difficulty': _difficulty.toJson(),
      };

  // --- Helpers ---

  static int _durationForAge(int age) {
    if (age <= 4) return 2;
    if (age <= 6) return 2;
    if (age <= 8) return 3;
    if (age <= 10) return 3;
    return 4;
  }

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

enum CptResponseResult {
  hit,
  falseAlarm,
  alreadyResponded,
}

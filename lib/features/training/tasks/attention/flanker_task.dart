import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Flanker Task — "指方向"
/// Central arrow direction must be identified while ignoring flanking arrows.
///
/// Congruent:   → → → → →  (all same)
/// Incongruent: → → ← → →  (center conflicts with flankers)
///
/// Difficulty: higher level → higher conflict ratio, faster pace.

// Arrow direction with display characters
enum ArrowDirection {
  left('←'),
  right('→');

  final String emoji;
  const ArrowDirection(this.emoji);

  static ArrowDirection random([Random? rng]) {
    final r = rng ?? Random();
    return values[r.nextInt(values.length)];
  }
}

class FlankerTask {
  final int childAge;
  final Random _random = Random();

  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters ---
  late double _conflictRatio; // 0.2 → 0.8 as level goes 1→10
  late int _responseWindowMs; // shorter at higher levels

  // --- State ---
  final int _totalTrials;
  int _currentTrial = 0;

  // --- Current trial ---
  ArrowDirection _centerDirection = ArrowDirection.right;
  List<ArrowDirection> _arrows = [];
  bool _isCongruent = true;
  int _trialStartMs = 0;
  bool _responded = false;

  // --- Metrics ---
  int _hits = 0;
  int _errors = 0;
  int _timeouts = 0;
  final List<int> _reactionTimes = [];

  // Breakdown by congruency
  int _congruentHits = 0;
  int _congruentTotal = 0;
  int _incongruentHits = 0;
  int _incongruentTotal = 0;

  FlankerTask({
    required this.childAge,
    int startLevel = 3,
    int totalTrials = 16,
  })  : _difficulty = AdaptiveDifficulty(
          gameId: 'attention_flanker',
          maxLevel: 10,
          upThreshold: 0.80,
          downThreshold: 0.55,
          windowSize: 8,
          startLevel: startLevel,
        ),
        _totalTrials = totalTrials {
    _applyLevelParams();
  }

  // --- Getters ---

  int get level => _difficulty.level;
  double get conflictRatio => _conflictRatio;
  int get responseWindowMs => _responseWindowMs;
  int get currentTrial => _currentTrial;
  int get totalTrials => _totalTrials;
  bool get isComplete => _currentTrial >= _totalTrials;
  double get progress => _currentTrial / _totalTrials;

  ArrowDirection get centerDirection => _centerDirection;
  List<ArrowDirection> get arrows => List.unmodifiable(_arrows);
  bool get isCongruent => _isCongruent;

  int get hits => _hits;
  int get errors => _errors;
  int get timeouts => _timeouts;

  double get accuracy =>
      (_hits + _errors + _timeouts) > 0
          ? _hits / (_hits + _errors + _timeouts)
          : 0;

  double get congruentAccuracy =>
      _congruentTotal > 0 ? _congruentHits / _congruentTotal : 0;

  double get incongruentAccuracy =>
      _incongruentTotal > 0 ? _incongruentHits / _incongruentTotal : 0;

  /// Flanker effect: how much worse on incongruent trials
  double get flankerEffect {
    if (_congruentTotal == 0 || _incongruentTotal == 0) return 0;
    return congruentAccuracy - incongruentAccuracy;
  }

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;
    // Higher level → more incongruent trials
    _conflictRatio = DifficultyParams.levelToDouble(lvl, 10, 0.20, 0.80);
    // Higher level → less time to respond
    _responseWindowMs = DifficultyParams.inverseInt(lvl, 10, 1000, 2500);
  }

  // --- Trial lifecycle ---

  /// Generate next flanker trial.
  void startNextTrial() {
    if (isComplete) return;

    _currentTrial++;
    _centerDirection = ArrowDirection.random(_random);
    _isCongruent = _random.nextDouble() >= _conflictRatio;

    // Build the arrow row: 5 positions total
    _arrows = List.filled(5, ArrowDirection.right);
    _arrows[2] = _centerDirection; // center

    if (_isCongruent) {
      // All arrows point same as center
      for (var i = 0; i < 5; i++) {
        _arrows[i] = _centerDirection;
      }
    } else {
      // Flankers point opposite of center
      final opposite = _centerDirection == ArrowDirection.left
          ? ArrowDirection.right
          : ArrowDirection.left;
      for (var i = 0; i < 5; i++) {
        if (i != 2) _arrows[i] = opposite;
      }
    }

    if (_isCongruent) {
      _congruentTotal++;
    } else {
      _incongruentTotal++;
    }

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
    _responded = false;
  }

  /// Player chose [direction].
  FlankerResult recordResponse(ArrowDirection direction) {
    if (_responded) return FlankerResult.alreadyResponded;
    _responded = true;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    final correct = direction == _centerDirection;

    if (correct) {
      _hits++;
      _reactionTimes.add(rt);
      _difficulty.recordResult(true);
      if (_isCongruent) {
        _congruentHits++;
      } else {
        _incongruentHits++;
      }
      return FlankerResult.hit;
    } else {
      _errors++;
      _difficulty.recordResult(false);
      return FlankerResult.error;
    }
  }

  /// Trial timed out without response.
  void recordTimeout() {
    if (_responded) return;
    _responded = true;
    _timeouts++;
    _difficulty.recordResult(false);
  }

  /// Re-read level and update params.
  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'attention_flanker',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _totalTrials,
        'completed_trials': _currentTrial,
        'hits': _hits,
        'errors': _errors,
        'timeouts': _timeouts,
        'accuracy': accuracy,
        'congruent_accuracy': congruentAccuracy,
        'incongruent_accuracy': incongruentAccuracy,
        'flanker_effect': flankerEffect,
        'mean_rt': meanReactionTime,
        'level': _difficulty.level,
        'conflict_ratio': _conflictRatio,
        'response_window_ms': _responseWindowMs,
        'difficulty': _difficulty.toJson(),
      };
}

enum FlankerResult { hit, error, alreadyResponded }

import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Simple Reaction Time Task — "闪电反应" ⚡
///
/// Wait for the screen to turn green, then tap as fast as possible.
/// Difficulty: higher levels → shorter foreperiod, more trials.
///
/// Uses AdaptiveDifficulty to auto-adjust based on child's performance.

class SimpleTask {
  final int childAge;
  final Random _random = Random();

  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters ---
  late int _foreperiodMinMs;
  late int _foreperiodMaxMs;
  late int maxTrials;
  late int _anticipationMinMs;

  // --- State ---
  int _trialCount = 0;
  bool _isComplete = false;
  SimplePhase _phase = SimplePhase.waiting;
  int _foreperiodMs = 0;
  int _stimulusOnMs = 0;

  // --- Metrics ---
  final List<int> _reactionTimes = [];
  int _anticipations = 0;
  int _earlyTaps = 0;

  SimpleTask({
    required this.childAge,
    int startLevel = 3,
  }) : _difficulty = AdaptiveDifficulty(
         gameId: 'reaction_simple',
         maxLevel: 10,
         upThreshold: 0.80,
         downThreshold: 0.55,
         windowSize: 8,
         startLevel: startLevel,
       ) {
    _applyLevelParams();
  }

  // --- Getters ---

  int get level => _difficulty.level;
  int get foreperiodMs => _foreperiodMs;
  int get trialCount => _trialCount;
  bool get isComplete => _isComplete;
  SimplePhase get phase => _phase;
  List<int> get reactionTimes => List.unmodifiable(_reactionTimes);
  int get anticipations => _anticipations;
  int get earlyTaps => _earlyTaps;
  double get progress => _trialCount / maxTrials;

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  double get medianReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    final sorted = List.of(_reactionTimes)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid].toDouble()
        : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  int get fastestReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a < b ? a : b);
  }

  int get slowestReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a > b ? a : b);
  }

  double get accuracy {
    final total = _trialCount + _anticipations + _earlyTaps;
    if (total == 0) return 0;
    return _trialCount / total;
  }

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;

    // Foreperiod: shorter at higher levels (harder to prepare)
    _foreperiodMinMs = DifficultyParams.inverseInt(lvl, 10, 500, 2000);
    _foreperiodMaxMs = DifficultyParams.inverseInt(lvl, 10, 800, 4000);

    // Trials: more at higher levels (requires sustained attention)
    maxTrials = DifficultyParams.levelToInt(lvl, 10, 20, 40);

    // Anticipation threshold tightens slightly at higher levels
    _anticipationMinMs = DifficultyParams.inverseInt(lvl, 10, 80, 150);
  }

  // --- Trial lifecycle ---

  void startTrial() {
    if (_isComplete) return;
    _phase = SimplePhase.waiting;
    _foreperiodMs = _foreperiodMinMs +
        _random.nextInt(_foreperiodMaxMs - _foreperiodMinMs + 1);
  }

  void showStimulus() {
    if (_phase != SimplePhase.waiting) return;
    _phase = SimplePhase.stimulus;
    _stimulusOnMs = DateTime.now().millisecondsSinceEpoch;
  }

  SimpleResult tap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_phase == SimplePhase.waiting) {
      _phase = SimplePhase.feedback;
      _earlyTaps++;
      _difficulty.recordResult(false);
      return SimpleResult.early;
    }

    if (_phase == SimplePhase.stimulus) {
      final rt = now - _stimulusOnMs;
      _phase = SimplePhase.feedback;

      if (rt < _anticipationMinMs) {
        _anticipations++;
        _difficulty.recordResult(false);
        return SimpleResult.anticipation;
      }

      _reactionTimes.add(rt);
      _trialCount++;
      final correct = rt <= 800; // "Good" reaction if ≤ 800ms
      _difficulty.recordResult(correct);
      if (_trialCount >= maxTrials) _isComplete = true;
      return SimpleResult.hit;
    }

    return SimpleResult.none;
  }

  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reaction_simple',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'mean_rt': meanReactionTime,
        'median_rt': medianReactionTime,
        'fastest_rt': fastestReactionTime,
        'slowest_rt': slowestReactionTime,
        'anticipations': _anticipations,
        'early_taps': _earlyTaps,
        'accuracy': accuracy,
        'level': _difficulty.level,
        'foreperiod_min_ms': _foreperiodMinMs,
        'foreperiod_max_ms': _foreperiodMaxMs,
        'child_age': childAge,
        'difficulty': _difficulty.toJson(),
        'reaction_times': _reactionTimes,
      };
}

enum SimplePhase { waiting, stimulus, feedback }

enum SimpleResult { hit, early, anticipation, none }

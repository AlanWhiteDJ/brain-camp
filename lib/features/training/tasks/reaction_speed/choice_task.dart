import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Choice Reaction Time Task — "左右开弓" 👈👉
///
/// A direction indicator (arrow/emoji) appears, and the child must tap
/// the corresponding side of the screen as fast as possible.
///
/// Difficulty: higher levels → more directions (2→4), shorter response window,
/// faster pace.

enum ChoiceDirection { left, right, up, down }

class ChoiceTask {
  final int childAge;
  final Random _random = Random();

  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters ---
  late int _responseWindowMs;
  late int _numDirections; // 2 or 4
  late int maxTrials;
  bool _directionUpEnabled = false;
  bool _directionDownEnabled = false;

  // --- State ---
  int _trialCount = 0;
  bool _isComplete = false;
  ChoicePhase _phase = ChoicePhase.waiting;
  ChoiceDirection? _currentDirection;
  int _stimulusOnMs = 0;

  // --- Metrics ---
  final List<int> _reactionTimes = [];
  int _correctCount = 0;
  int _wrongDirectionCount = 0;
  int _timeoutCount = 0;
  int _earlyTapCount = 0;

  ChoiceTask({
    required this.childAge,
    int startLevel = 3,
  }) : _difficulty = AdaptiveDifficulty(
         gameId: 'reaction_choice',
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
  int get responseWindowMs => _responseWindowMs;
  int get numDirections => _numDirections;
  int get trialCount => _trialCount;
  bool get isComplete => _isComplete;
  ChoicePhase get phase => _phase;
  ChoiceDirection? get currentDirection => _currentDirection;
  bool get upEnabled => _directionUpEnabled;
  bool get downEnabled => _directionDownEnabled;
  double get progress => maxTrials > 0 ? _trialCount / maxTrials : 0;

  List<int> get reactionTimes => List.unmodifiable(_reactionTimes);
  int get correctCount => _correctCount;
  int get wrongDirectionCount => _wrongDirectionCount;
  int get timeoutCount => _timeoutCount;
  int get earlyTapCount => _earlyTapCount;

  int get totalResponses =>
      _correctCount + _wrongDirectionCount + _timeoutCount + _earlyTapCount;

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

  double get accuracy {
    final total = totalResponses;
    if (total == 0) return 0;
    return _correctCount / total;
  }

  String get directionEmoji {
    if (_currentDirection == null) return '❓';
    switch (_currentDirection!) {
      case ChoiceDirection.left:
        return '👈';
      case ChoiceDirection.right:
        return '👉';
      case ChoiceDirection.up:
        return '👆';
      case ChoiceDirection.down:
        return '👇';
    }
  }

  String directionLabel(ChoiceDirection dir) {
    switch (dir) {
      case ChoiceDirection.left:
        return '左';
      case ChoiceDirection.right:
        return '右';
      case ChoiceDirection.up:
        return '上';
      case ChoiceDirection.down:
        return '下';
    }
  }

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;

    // Response window: shorter at higher levels
    _responseWindowMs = DifficultyParams.inverseInt(lvl, 10, 600, 2000);

    // Number of directions: 2 at low levels, 4 at high levels
    if (lvl <= 3) {
      _numDirections = 2;
      _directionUpEnabled = false;
      _directionDownEnabled = false;
    } else if (lvl <= 6) {
      _numDirections = 3; // left, right, up (up has lower probability)
      _directionUpEnabled = true;
      _directionDownEnabled = false;
    } else {
      _numDirections = 4;
      _directionUpEnabled = true;
      _directionDownEnabled = true;
    }

    // Trials: more at higher levels
    maxTrials = DifficultyParams.levelToInt(lvl, 10, 15, 30);
  }

  // --- Direction generation ---

  ChoiceDirection _generateDirection() {
    // Build weighted pool based on enabled directions
    final pool = <ChoiceDirection>[];
    // left and right always primary (equal weight)
    pool.addAll([ChoiceDirection.left, ChoiceDirection.right]);
    if (_directionUpEnabled) pool.add(ChoiceDirection.up);
    if (_directionDownEnabled) pool.add(ChoiceDirection.down);
    return pool[_random.nextInt(pool.length)];
  }

  // --- Trial lifecycle ---

  void startNextTrial() {
    if (_isComplete) return;
    _currentDirection = _generateDirection();
    _phase = ChoicePhase.stimulus;
    _stimulusOnMs = DateTime.now().millisecondsSinceEpoch;
  }

  ChoiceResult tap(ChoiceDirection tappedDirection) {
    if (_phase == ChoicePhase.waiting) {
      _earlyTapCount++;
      _difficulty.recordResult(false);
      return ChoiceResult.early;
    }

    if (_phase != ChoicePhase.stimulus) return ChoiceResult.none;

    final rt = DateTime.now().millisecondsSinceEpoch - _stimulusOnMs;

    if (tappedDirection == _currentDirection) {
      // Correct!
      _trialCount++;
      _correctCount++;
      _reactionTimes.add(rt);
      _phase = ChoicePhase.feedback;
      final fast = rt <= _responseWindowMs * 0.6;
      _difficulty.recordResult(fast);
      if (_trialCount >= maxTrials) _isComplete = true;
      return ChoiceResult.correct;
    } else {
      // Wrong direction
      _wrongDirectionCount++;
      _phase = ChoicePhase.feedback;
      _difficulty.recordResult(false);
      return ChoiceResult.wrongDirection;
    }
  }

  void handleTimeout() {
    if (_phase != ChoicePhase.stimulus) return;
    _timeoutCount++;
    _phase = ChoicePhase.feedback;
    _difficulty.recordResult(false);
    _trialCount++;
    if (_trialCount >= maxTrials) _isComplete = true;
  }

  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reaction_choice',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'wrong_direction': _wrongDirectionCount,
        'timeout_count': _timeoutCount,
        'early_tap_count': _earlyTapCount,
        'mean_rt': meanReactionTime,
        'median_rt': medianReactionTime,
        'accuracy': accuracy,
        'level': _difficulty.level,
        'num_directions': _numDirections,
        'response_window_ms': _responseWindowMs,
        'child_age': childAge,
        'difficulty': _difficulty.toJson(),
        'reaction_times': _reactionTimes,
      };
}

enum ChoicePhase { waiting, stimulus, feedback }
enum ChoiceResult { correct, wrongDirection, early, timeout, none }

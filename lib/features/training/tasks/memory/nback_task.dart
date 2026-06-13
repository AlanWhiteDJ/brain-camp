/// N-Back Task (Memory Module)
/// Game 2: 回看一下
///
/// Position-based N-Back: 9 squares in a 3×3 grid.
/// One lights up per trial. Child responds if current position
/// matches the one shown N steps ago.
/// Difficulty: faster interval, higher N-level, more trials.

import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class NBackTask {
  final int childAge;
  final Random _random = Random();
  final AdaptiveDifficulty _difficulty;

  // State
  int _currentTrial = 0;
  int _totalTrials = 0;
  int _totalCorrect = 0;
  int _correctInRound = 0;
  int _roundTotal = 0;

  // Sequence: list of positions (0-8)
  final List<int> _positionHistory = [];
  int _currentPosition = -1;
  bool _showingStimulus = false;
  bool _awaitingResponse = false;
  bool _lastResponseCorrect = false;
  bool _hasResponded = false;

  bool _isComplete = false;

  NBackTask({
    required this.childAge,
    AdaptiveDifficulty? difficulty,
  }) : _difficulty = difficulty ??
            AdaptiveDifficulty(
              gameId: 'nback',
              maxLevel: 10,
              upThreshold: 0.82,
              downThreshold: 0.55,
              windowSize: 10,
              startLevel: _startLevelForAge(6),
            );

  static int _startLevelForAge(int age) {
    if (age <= 4) return 1;
    if (age <= 6) return 1;
    if (age <= 8) return 2;
    if (age <= 10) return 3;
    return 4;
  }

  // --- Difficulty-driven parameters ---

  int get difficultyLevel => _difficulty.level;

  /// N-level: 2-back at low levels, 3-back at level 7+
  int get nLevel {
    if (_difficulty.level <= 3) return 1;
    if (_difficulty.level <= 6) return 2;
    return 3;
  }

  /// Stimulus display duration in ms
  int get stimulusDurationMs {
    return DifficultyParams.inverseInt(_difficulty.level, 10, 600, 1500);
  }

  /// Interval between trials in ms
  int get intervalMs {
    return DifficultyParams.inverseInt(_difficulty.level, 10, 400, 1000);
  }

  /// Total trials per round
  int get totalRounds {
    return DifficultyParams.levelToInt(_difficulty.level, 10, 10, 25);
  }

  /// Probability that current trial IS a match (~25%)
  double get matchProbability => 0.25;

  // --- Getters ---

  int get currentTrial => _currentTrial;
  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;
  int get currentPosition => _currentPosition;
  bool get showingStimulus => _showingStimulus;
  bool get awaitingResponse => _awaitingResponse;
  bool get hasResponded => _hasResponded;
  bool get lastResponseCorrect => _lastResponseCorrect;
  bool get isComplete => _isComplete;
  int get correctInRound => _correctInRound;
  int get roundTotal => _roundTotal;
  AdaptiveDifficulty get difficulty => _difficulty;
  double get accuracy => _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;

  /// Generate the next position. Returns [position, isMatch].
  MapEntry<int, bool> nextStimulus() {
    _hasResponded = false;
    _showingStimulus = true;
    _awaitingResponse = false;

    int pos;
    bool isMatch;

    // Fill the history buffer with initial positions
    while (_positionHistory.length < nLevel) {
      _positionHistory.add(_random.nextInt(9));
    }

    // Decide if this should be a match
    if (_positionHistory.length >= nLevel &&
        _random.nextDouble() < matchProbability) {
      // Match: repeat the position from N steps ago
      pos = _positionHistory[_positionHistory.length - nLevel];
      isMatch = true;
    } else {
      // Non-match: random position (but try to avoid accidental matches)
      int tries = 0;
      do {
        pos = _random.nextInt(9);
        tries++;
      } while (_positionHistory.length >= nLevel &&
               pos == _positionHistory[_positionHistory.length - nLevel] &&
               tries < 20);
      isMatch = false;
    }

    _positionHistory.add(pos);
    _currentPosition = pos;

    return MapEntry(pos, isMatch);
  }

  void finishStimulus() {
    _showingStimulus = false;
    _awaitingResponse = true;
  }

  /// Child responds with match/no-match. Returns correct?.
  /// [respondedMatch] = true if child says "match", false if "no match".
  bool respond(bool respondedMatch) {
    if (!_awaitingResponse || _hasResponded) return false;

    _hasResponded = true;
    _awaitingResponse = false;

    // Actual match status
    final actualMatch = _positionHistory.length > nLevel &&
        _currentPosition == _positionHistory[_positionHistory.length - 1 - nLevel];

    final correct = respondedMatch == actualMatch;
    _lastResponseCorrect = correct;

    _totalTrials++;
    _roundTotal++;
    if (correct) {
      _totalCorrect++;
      _correctInRound++;
    }

    _difficulty.recordResult(correct);

    _currentTrial++;
    if (_currentTrial >= totalRounds) {
      _isComplete = true;
    }

    return correct;
  }

  Map<String, dynamic> toSessionData() {
    final diffData = _difficulty.toJson();
    return {
      'task_id': 'nback',
      'timestamp': DateTime.now().toIso8601String(),
      'n_level': nLevel,
      'total_trials': _totalTrials,
      'total_correct': _totalCorrect,
      'correct_in_round': _correctInRound,
      'round_total': _roundTotal,
      'accuracy': accuracy,
      'child_age': childAge,
      ...diffData,
    };
  }
}

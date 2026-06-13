import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Number Line Estimation Task — "在哪呢"
/// Child sees a number line and drags a marker to where N belongs.
/// Difficulty: larger range, harder numbers (decimals at high levels).

class LineTask {
  final int childAge;
  final AdaptiveDifficulty _difficulty;
  final Random _random = Random();

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;

  // Current trial
  double _targetNumber = 0;
  double _rangeMin = 0;
  double _rangeMax = 100;
  double? _placedValue; // where the child placed the marker
  bool _responded = false;

  // Timing
  int _trialStartMs = 0;
  final List<int> _reactionTimes = [];
  final List<double> _errors = []; // absolute error per trial

  LineTask({required this.childAge})
      : _difficulty = AdaptiveDifficulty(
          gameId: 'line',
          maxLevel: 255,
          startLevel: _startLevelForAge(childAge),
        );

  static int _startLevelForAge(int age) {
    return (age * 14).clamp(20, 200);
  }

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  double get targetNumber => _targetNumber;
  double get rangeMin => _rangeMin;
  double get rangeMax => _rangeMax;
  double? get placedValue => _placedValue;
  bool get isComplete => _isComplete;
  int get difficultyLevel => _difficulty.level;
  double get accuracy =>
      _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get meanError {
    if (_errors.isEmpty) return 0;
    return _errors.reduce((a, b) => a + b) / _errors.length;
  }
  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }
  double get progress {
    final total = _totalTrials;
    return _trialCount / total;
  }

  int get _totalTrials => (10 + childAge * 3).clamp(10, 40);

  /// Difficulty-driven range
  double get _rangeSize {
    // Level 1: range 10 (e.g. 0-10)
    // Level 5: range 100 (e.g. 0-100)
    // Level 10: range 1000 (e.g. 0-1000)
    return DifficultyParams.levelToDouble(
      _difficulty.level, _difficulty.maxLevel, 10, 1000,
    );
  }

  bool get _useDecimals =>
      _difficulty.level >= 7; // decimals at high difficulty

  /// Error tolerance: acceptable error as fraction of range
  /// Level 1: 0.20 (20% of range → easy)
  /// Level 10: 0.08 (8% of range → hard)
  double get _tolerance {
    return DifficultyParams.inverseDouble(
      _difficulty.level, _difficulty.maxLevel, 0.08, 0.22,
    );
  }

  /// Generate next trial
  void nextTrial() {
    if (_isComplete) return;

    final size = _rangeSize;
    // Pick a "nice" starting minimum
    _rangeMin = (_random.nextInt(3)) * (size / 10).round().toDouble();
    _rangeMax = _rangeMin + size;

    // Generate target within range
    if (_useDecimals) {
      // Decimal target (one decimal place)
      _targetNumber = (_rangeMin +
              _random.nextDouble() * (size - 1))
          .clamp(_rangeMin + 0.5, _rangeMax - 0.5);
      _targetNumber = (_targetNumber * 10).round() / 10.0;
    } else {
      _targetNumber = (_rangeMin + 1 + _random.nextInt(size.toInt() - 1))
          .toDouble()
          .clamp(_rangeMin + 1, _rangeMax - 1);
    }

    _placedValue = null;
    _responded = false;
    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Submit the child's placement. Returns whether it's within tolerance.
  bool submitPlacement(double value) {
    if (_responded) return false;
    _responded = true;
    _trialCount++;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    _placedValue = value;

    final rangeSpan = _rangeMax - _rangeMin;
    final error = (value - _targetNumber).abs();
    final errorFraction = error / rangeSpan;
    _errors.add(errorFraction);

    final correct = errorFraction <= _tolerance;
    if (correct) _correctCount++;

    _difficulty.recordResult(correct);

    if (_trialCount >= _totalTrials) {
      _isComplete = true;
    }

    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'line',
        'game': 'number_line',
        'game_name': '在哪呢',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'mean_error_fraction': meanError,
        'mean_rt': meanReactionTime,
        'final_level': _difficulty.level,
        'difficulty_progress': _difficulty.accuracy,
        'child_age': childAge,
      };
}

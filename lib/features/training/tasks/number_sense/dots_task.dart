import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Dot Comparison Task — "比比看"
/// Child sees two panels with colored dots and picks which has more.
/// Difficulty: more dots, smaller ratio difference between sides.

class DotsTask {
  final int childAge;
  final AdaptiveDifficulty _difficulty;
  final Random _random = Random();

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  final List<int> _currentDots = [0, 0];
  int _correctSide = 0; // 0=left, 1=right
  bool _responded = false;
  bool _isComplete = false;

  // Timing
  int _trialStartMs = 0;
  final List<int> _reactionTimes = [];

  DotsTask({required this.childAge})
      : _difficulty = AdaptiveDifficulty(
          gameId: 'dots',
          maxLevel: 10,
          upThreshold: 0.75,
          downThreshold: 0.50,
          windowSize: 6,
          startLevel: _startLevelForAge(childAge),
        );

  static int _startLevelForAge(int age) {
    if (age <= 4) return 1; // very young — easy start
    if (age <= 5) return 2;
    if (age <= 7) return 3;
    if (age <= 9) return 5;
    return 6;
  }

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  List<int> get currentDots => List.unmodifiable(_currentDots);
  int get correctSide => _correctSide;
  bool get isComplete => _isComplete;
  int get difficultyLevel => _difficulty.level;
  double get accuracy =>
      _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }
  double get progress {
    // Dynamic trial count: scales with age, min 10, max 40
    final total = (10 + childAge * 3).clamp(10, 40);
    return _trialCount / total;
  }

  int get _totalTrials => (10 + childAge * 3).clamp(10, 40);

  /// Difficulty-driven parameters
  int get _maxDots {
    // Level 1: ~5 dots → Level 10: ~30 dots
    return DifficultyParams.levelToInt(
        _difficulty.level, _difficulty.maxLevel, 5, 30);
  }

  double get _minRatio {
    // Level 1: easy — ratio 0.4 (big side has 2.5x more)
    // Level 10: hard — ratio 0.85 (very close counts)
    return DifficultyParams.inverseDouble(
        _difficulty.level, _difficulty.maxLevel, 0.35, 0.88);
  }

  /// Generate next trial
  void nextTrial() {
    if (_isComplete) return;

    final maxDots = _maxDots;
    final minRatio = _minRatio;

    // Generate the smaller count
    final smaller = _random.nextInt(maxDots ~/ 2) + 1;
    // The bigger must be at least smaller / minRatio
    final minBigger = (smaller / minRatio).ceil();
    final maxBigger = maxDots;
    if (minBigger > maxBigger) {
      // Fallback: just make bigger side significantly different
      final bigger = (smaller * 1.3).round().clamp(smaller + 1, maxDots);
      _randomizeSides(smaller, bigger);
      _finishGeneration();
      return;
    }
    final bigger = minBigger + _random.nextInt(maxBigger - minBigger + 1);

    _randomizeSides(smaller, bigger);
    _finishGeneration();
  }

  void _randomizeSides(int smaller, int bigger) {
    _correctSide = _random.nextInt(2);
    if (_correctSide == 0) {
      _currentDots[0] = bigger;
      _currentDots[1] = smaller;
    } else {
      _currentDots[0] = smaller;
      _currentDots[1] = bigger;
    }
  }

  void _finishGeneration() {
    _responded = false;
    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Check answer, return whether correct
  bool checkAnswer(int chosenSide) {
    if (_responded) return false;
    _responded = true;
    _trialCount++;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = chosenSide == _correctSide;
    if (correct) _correctCount++;

    _difficulty.recordResult(correct);

    if (_trialCount >= _totalTrials) {
      _isComplete = true;
    }

    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'dots',
        'game': 'dot_comparison',
        'game_name': '比比看',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'mean_rt': meanReactionTime,
        'final_level': _difficulty.level,
        'difficulty_progress': _difficulty.progress,
        'child_age': childAge,
        'reaction_times': _reactionTimes,
      };
}

import 'dart:math';
import 'dart:ui';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Subitizing Task — "一眼看"
/// Brief flash of dots, child picks the correct count from options.
/// Difficulty: more dots, shorter flash duration.

class SubitizeTask {
  final int childAge;
  final AdaptiveDifficulty _difficulty;
  final Random _random = Random();

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;

  // Current trial
  int _dotCount = 0;
  List<int> _options = []; // 4 choices
  List<Offset> _dotPositions = []; // random positions for the dots
  int _correctAnswer = 0;
  bool _responded = false;

  // Timing
  int _trialStartMs = 0;
  final List<int> _reactionTimes = [];

  SubitizeTask({required this.childAge})
      : _difficulty = AdaptiveDifficulty(
          gameId: 'subitize',
          maxLevel: 255,
          startLevel: _startLevelForAge(childAge),
        );

  static int _startLevelForAge(int age) {
    return (age * 14).clamp(20, 200);
  }

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  int get dotCount => _dotCount;
  List<int> get options => List.unmodifiable(_options);
  List<Offset> get dotPositions => List.unmodifiable(_dotPositions);
  int get correctAnswer => _correctAnswer;
  bool get isComplete => _isComplete;
  int get difficultyLevel => _difficulty.level;
  double get accuracy =>
      _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }
  double get progress {
    final total = _totalTrials;
    return _trialCount / total;
  }

  int get _totalTrials => (10 + childAge * 3).clamp(10, 40);

  /// Dot count: increases with difficulty level
  /// Level 1: 1-3 dots → Level 10: 8-15 dots
  int get _maxDots {
    return DifficultyParams.levelToInt(
      _difficulty.level, _difficulty.maxLevel, 3, 15,
    );
  }

  /// Flash duration in ms: decreases with difficulty
  /// Level 1: 1200ms → Level 10: 200ms
  int get flashDurationMs {
    return DifficultyParams.inverseInt(
      _difficulty.level, _difficulty.maxLevel, 200, 1200,
    );
  }

  /// Generate next trial
  void nextTrial() {
    if (_isComplete) return;

    final maxDots = _maxDots;
    _dotCount = _random.nextInt(maxDots) + 1;
    _correctAnswer = _dotCount;

    // Generate 4 distinct options including the correct one
    _options = _generateOptions(_dotCount, maxDots);

    // Generate random dot positions in a constrained area
    _dotPositions = _generatePositions(_dotCount);

    _responded = false;
    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  List<int> _generateOptions(int correct, int maxDots) {
    final options = <int>{correct};
    final rng = Random();

    // Generate plausible distractors near the correct count
    while (options.length < 4) {
      int distractor;
      final offset = rng.nextInt(4) + 1; // 1-4 away
      if (rng.nextBool()) {
        distractor = correct + offset;
        if (distractor > maxDots) distractor = correct - offset;
      } else {
        distractor = correct - offset;
        if (distractor < 1) distractor = correct + offset;
      }
      distractor = distractor.clamp(1, maxDots + 2);
      options.add(distractor);
    }

    // Shuffle
    final list = options.toList();
    list.shuffle(rng);
    return list;
  }

  List<Offset> _generatePositions(int count) {
    // Generate non-overlapping positions in a roughly circular area
    final positions = <Offset>[];
    final rng = Random();
    const minDist = 0.12;

    for (int i = 0; i < count; i++) {
      int attempts = 0;
      while (attempts < 50) {
        final x = 0.1 + rng.nextDouble() * 0.8;
        final y = 0.1 + rng.nextDouble() * 0.8;

        bool tooClose = false;
        for (final p in positions) {
          final dx = p.dx - x;
          final dy = p.dy - y;
          if (dx * dx + dy * dy < minDist * minDist) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          positions.add(Offset(x, y));
          break;
        }
        attempts++;
      }

      // Fallback: just add a random position
      if (positions.length <= i) {
        positions.add(Offset(
          0.1 + rng.nextDouble() * 0.8,
          0.1 + rng.nextDouble() * 0.8,
        ));
      }
    }

    return positions;
  }

  /// Check answer, return whether correct
  bool checkAnswer(int chosen) {
    if (_responded) return false;
    _responded = true;
    _trialCount++;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = chosen == _correctAnswer;
    if (correct) _correctCount++;

    _difficulty.recordResult(correct);

    if (_trialCount >= _totalTrials) {
      _isComplete = true;
    }

    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'subitize',
        'game': 'subitizing',
        'game_name': '一眼看',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'mean_rt': meanReactionTime,
        'final_level': _difficulty.level,
        'difficulty_progress': _difficulty.accuracy,
        'child_age': childAge,
      };
}

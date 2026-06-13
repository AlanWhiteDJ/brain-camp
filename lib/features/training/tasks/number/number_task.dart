import 'dart:math';
import '../../../../core/utils/constants.dart';

/// Number Sense Task
/// Dot comparison / magnitude estimation for young children
/// "Which side has more dots?"

class NumberTask {
  final int childAge;
  final Random _random = Random();

  // Configuration
  late int _totalTrials;
  late int _maxDots;

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  final List<int> _currentDots = [0, 0]; // left, right
  int _correctSide = 0; // 0=left, 1=right
  bool _responded = false;
  bool _isComplete = false;

  // Timing
  int _trialStartMs = 0;
  final List<int> _reactionTimes = [];

  NumberTask({required this.childAge}) {
    _totalTrials = TrainingConstants.trainingDurationForAge(childAge) * 5;
    _maxDots = childAge <= 4 ? 5 : childAge <= 6 ? 10 : childAge <= 8 ? 15 : 20;
  }

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  List<int> get currentDots => List.unmodifiable(_currentDots);
  int get correctSide => _correctSide;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }
  double get progress => _totalTrials > 0 ? _trialCount / _totalTrials : 0;

  /// Generate next trial
  void nextTrial() {
    if (_isComplete) return;

    // Generate two dot counts with meaningful difference
    final base = _random.nextInt(_maxDots - 1) + 1;
    // difference depends on age (bigger difference for younger kids)
    final minDiff = childAge <= 4 ? 2 : childAge <= 6 ? 1 : 1;
    var diff = _random.nextInt(_maxDots - base) + minDiff;
    if (diff < minDiff) diff = minDiff;

    final more = base + diff;
    final less = base;

    // Randomize which side has more
    _correctSide = _random.nextInt(2);
    if (_correctSide == 0) {
      _currentDots[0] = more;
      _currentDots[1] = less;
    } else {
      _currentDots[0] = less;
      _currentDots[1] = more;
    }

    _responded = false;
    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Check answer
  bool checkAnswer(int chosenSide) {
    if (_responded) return false;
    _responded = true;
    _trialCount++;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = chosenSide == _correctSide;
    if (correct) _correctCount++;

    if (_trialCount >= _totalTrials) {
      _isComplete = true;
    }

    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'number',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _totalTrials,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'mean_rt': meanReactionTime,
        'max_dots': _maxDots,
        'child_age': childAge,
      };
}

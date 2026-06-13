import 'dart:math';

/// Spatial Reasoning Task
/// Mental rotation / visual matching for kids
/// "Which one is the same shape?"

class SpatialTask {
  final int childAge;
  final Random _random = Random();

  static const int totalTrials = 20;

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];
  int _trialStartMs = 0;

  // Current trial
  late String _targetEmoji;
  late int _targetRotation;
  late List<SpatialOption> _options;
  late int _correctIdx;

  // Emoji shapes that are clearly different even when rotated
  static const _shapes = ['🦊', '🐱', '🚗', '🏠', '⭐', '✈️'];
  static const _rotations = [0, 90, 180, 270];

  SpatialTask({required this.childAge});

  List<SpatialOption> get options => _options;
  int get correctIdx => _correctIdx;
  String get targetEmoji => _targetEmoji;
  int get targetRotation => _targetRotation;
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;

  void nextTrial() {
    if (_isComplete) return;

    // Pick a target shape and rotation
    _targetEmoji = _shapes[_random.nextInt(_shapes.length)];
    _targetRotation = _rotations[_random.nextInt(_rotations.length)];

    // Generate 4 options
    // 1 correct: same shape, different rotation (but rotatable to match)
    // 3 wrong: different shapes, or same shape but clearly different
    final wrongShapes = _shapes.where((s) => s != _targetEmoji).toList()..shuffle(_random);

    _options = [
      SpatialOption(_targetEmoji, _correctRotation()),
      SpatialOption(wrongShapes[0], _randomRotation()),
      SpatialOption(wrongShapes[1], _randomRotation()),
      SpatialOption(wrongShapes[2], _randomRotation()),
    ];

    // Shuffle
    _correctIdx = 0; // correct is at index 0 initially
    _options.shuffle(_random);
    _correctIdx = _options.indexWhere((o) => o.emoji == _targetEmoji);

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  int _correctRotation() {
    // The "correct" option shows the same shape at a different rotation
    // from the target. Kid must mentally rotate.
    final rotations = _rotations.where((r) => r != _targetRotation).toList();
    return rotations[_random.nextInt(rotations.length)];
  }

  int _randomRotation() => _rotations[_random.nextInt(_rotations.length)];

  bool checkAnswer(int chosenIdx) {
    _trialCount++;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = chosenIdx == _correctIdx;
    if (correct) _correctCount++;
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'spatial',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'child_age': childAge,
      };
}

class SpatialOption {
  final String emoji;
  final int rotation;
  const SpatialOption(this.emoji, this.rotation);
}

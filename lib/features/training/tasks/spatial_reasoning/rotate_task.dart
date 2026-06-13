import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class RotateTask {
  final int childAge;
  final Random _random = Random();
  late AdaptiveDifficulty _diff;

  static const totalTrials = 24;
  static const _shapes = ['🦊', '🐱', '🚗', '🏠', '⭐', '✈️', '🐶', '🐰'];
  static const _rotations = [0, 90, 180, 270];

  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];

  late String _targetEmoji;
  late int _targetRotation;
  late List<String> _options;
  late int _correctIdx;
  int _numOptions = 4;

  RotateTask({required this.childAge}) {
    _diff = AdaptiveDifficulty(gameId: 'spatial_rotate', startLevel: childAge <= 4 ? 1 : childAge <= 6 ? 2 : 3);
  }

  String get targetEmoji => _targetEmoji;
  int get targetRotation => _targetRotation;
  List<String> get options => _options;
  int get correctIdx => _correctIdx;
  int get numOptions => _numOptions;
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  int get level => _diff.level;

  void nextTrial() {
    if (_isComplete) return;
    // Difficulty parameters
    _numOptions = DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 3, 6);
    final rotationCount = DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 2, 4);

    final availableRotations = _rotations.take(rotationCount).toList();
    _targetEmoji = _shapes[_random.nextInt(_shapes.length)];
    _targetRotation = availableRotations[_random.nextInt(availableRotations.length)];

    // Build options: 1 correct + n-1 wrong
    final wrongShapes = _shapes.where((s) => s != _targetEmoji).toList()..shuffle(_random);
    _options = [_targetEmoji];
    for (int i = 0; i < _numOptions - 1; i++) {
      _options.add(wrongShapes[i % wrongShapes.length]);
    }
    _options.shuffle(_random);
    _correctIdx = _options.indexOf(_targetEmoji);
  }

  bool checkAnswer(int chosenIdx) {
    _trialCount++;
    final correct = chosenIdx == _correctIdx;
    if (correct) _correctCount++;
    _diff.recordResult(correct);
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'spatial_rotate', 'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount, 'correct_count': _correctCount,
        'accuracy': accuracy, 'final_level': _diff.level, 'child_age': childAge,
      };
}

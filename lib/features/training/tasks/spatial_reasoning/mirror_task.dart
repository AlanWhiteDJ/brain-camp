import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class MirrorTask {
  final int childAge;
  final Random _random = Random();
  late AdaptiveDifficulty _diff;

  static const totalTrials = 18;
  static const _patterns = [
    ['🔴', '🔵', '🔴'], ['⭐', '🌟', '⭐'], ['🌙', '☀️', '🌙'],
    ['🟢', '🟡', '🟢'], ['❤️', '💙', '❤️'], ['🔶', '🔷', '🔶'],
  ];

  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;

  late List<String> _half; // visible half
  late List<String> _options; // 4 choices (1 correct full)
  late String _correctFull;
  late int _correctIdx;
  int _numOptions = 4;

  MirrorTask({required this.childAge}) {
    _diff = AdaptiveDifficulty(gameId: 'spatial_mirror', startLevel: 50);
  }

  List<String> get half => _half;
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
    _numOptions = DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 3, 6);
    final patternLength = DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 3, 5);

    // Pick a pattern and create left half
    final pattern = _patterns[_random.nextInt(_patterns.length)];
    _half = pattern.take(patternLength).toList();

    // Create mirrored full: [half..., reversed half...]
    _correctFull = '${_half.join(' ')} 🫸 ${_half.reversed.join(' ')}';

    // Generate wrong options by shuffling or altering
    final wrongPatterns = _patterns.where((p) => p != pattern).toList()..shuffle(_random);
    _options = [_correctFull];
    while (_options.length < _numOptions) {
      final wp = wrongPatterns[_options.length % wrongPatterns.length];
      final altered = wp.take(patternLength).toList();
      if (_random.nextBool()) altered[1] = _half[1]; // make one element match (tricky)
      _options.add('${altered.join(' ')} 🫸 ${altered.reversed.join(' ')}');
    }
    _options.shuffle(_random);
    _correctIdx = _options.indexOf(_correctFull);
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
        'task_id': 'spatial_mirror', 'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount, 'correct_count': _correctCount,
        'accuracy': accuracy, 'final_level': _diff.level, 'child_age': childAge,
      };
}

import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class BlocksTask {
  final int childAge;
  final Random _random = Random();
  late AdaptiveDifficulty _diff;

  static const totalTrials = 16;
  static const _colors = [0xFFEF5350, 0xFF42A5F5, 0xFFFFCA28, 0xFF66BB6A, 0xFFAB47BC, 0xFFFF7043];

  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];

  late int _gridSize; // 2, 3, or 4
  late List<int> _targetPattern; // color indices
  late List<int> _userPattern;
  int _nextTapIdx = 0;

  BlocksTask({required this.childAge}) {
    _diff = AdaptiveDifficulty(gameId: 'spatial_blocks', startLevel: childAge <= 4 ? 1 : childAge <= 6 ? 2 : 3);
  }

  int get gridSize => _gridSize;
  List<int> get targetPattern => _targetPattern;
  List<int> get userPattern => _userPattern;
  int get nextTapIdx => _nextTapIdx;
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  int get level => _diff.level;

  static int getColor(int idx) => _colors[idx % _colors.length];

  void nextTrial() {
    if (_isComplete) return;
    _gridSize = DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 2, 4);
    final totalCells = _gridSize * _gridSize;
    final numColored = min(totalCells, DifficultyParams.levelToInt(_diff.level, _diff.maxLevel, 3, totalCells));

    // Generate target pattern
    final colorPool = min(_gridSize + 1, _colors.length);
    _targetPattern = List.filled(totalCells, -1);
    final indices = List.generate(totalCells, (i) => i)..shuffle(_random);
    for (int i = 0; i < numColored; i++) {
      final colorIdx = _random.nextInt(colorPool);
      _targetPattern[indices[i]] = colorIdx;
    }

    _userPattern = List.filled(totalCells, -1);
    _nextTapIdx = 0;
  }

  /// Record a cell tap. Returns the color to set, or -1 if invalid.
  int tapCell(int cellIdx) {
    if (_targetPattern[cellIdx] < 0) return -1; // tap on empty
    _userPattern[cellIdx] = _targetPattern[cellIdx];
    _nextTapIdx++;
    return _targetPattern[cellIdx];
  }

  /// Check if all colored cells have been tapped correctly
  bool checkComplete() {
    for (int i = 0; i < _targetPattern.length; i++) {
      if (_targetPattern[i] >= 0 && _userPattern[i] != _targetPattern[i]) return false;
    }
    _trialCount++; _correctCount++;
    _diff.recordResult(true);
    if (_trialCount >= totalTrials) _isComplete = true;
    return true;
  }

  void giveUp() {
    _trialCount++;
    _diff.recordResult(false);
    if (_trialCount >= totalTrials) _isComplete = true;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'spatial_blocks', 'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount, 'correct_count': _correctCount,
        'accuracy': accuracy, 'final_level': _diff.level, 'child_age': childAge,
      };
}

/// Pattern Memory Grid Task (Memory Module)
/// Game 3: 图案记忆
///
/// A grid pattern is shown briefly, then the child reproduces it by
/// tapping cells. Difficulty scales grid size (2×2→5×5) and display time.
/// Uses AdaptiveDifficulty for automatic leveling.

import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class GridTask {
  final int childAge;
  final Random _random = Random();
  final AdaptiveDifficulty _difficulty;

  // Grid size
  int _gridSize = 2;

  // Pattern state
  Set<int> _targetPattern = {};    // cells that should be ON
  Set<int> _tappedCells = {};      // cells user has tapped

  // Flow state
  bool _isShowingPattern = true;
  bool _isResponding = false;
  bool _isComplete = false;

  // Stats
  int _totalTrials = 0;
  int _totalCorrect = 0;
  int _failsAtCurrentSize = 0;

  GridTask({
    required this.childAge,
    AdaptiveDifficulty? difficulty,
  }) : _difficulty = difficulty ??
            AdaptiveDifficulty(
              gameId: 'grid_memory',
              maxLevel: 10,
              upThreshold: 0.80,
              downThreshold: 0.55,
              windowSize: 5,
              startLevel: _startLevelForAge(6),
            ) {
    _gridSize = gridSizeForLevel(_difficulty.level);
  }

  static int _startLevelForAge(int age) {
    if (age <= 4) return 1;
    if (age <= 6) return 2;
    if (age <= 8) return 3;
    if (age <= 10) return 4;
    return 5;
  }

  // --- Difficulty-driven parameters ---

  int get difficultyLevel => _difficulty.level;
  int get maxLevel => _difficulty.maxLevel;

  /// Grid size: level 1→2×2, level 5→3×3, level 8→4×4, level 10→5×5
  static int gridSizeForLevel(int level) {
    if (level <= 3) return 2;
    if (level <= 6) return 3;
    if (level <= 8) return 4;
    return 5;
  }

  /// Number of cells to highlight in the target pattern
  int get patternFillCount {
    final totalCells = _gridSize * _gridSize;
    if (totalCells <= 4) return max(1, totalCells ~/ 2);
    if (totalCells <= 9) return 3 + _random.nextInt(3); // 3-5
    if (totalCells <= 16) return 4 + _random.nextInt(4); // 4-7
    return 6 + _random.nextInt(5); // 6-10
  }

  /// Display time in ms (shorter at higher levels)
  int get displayTimeMs {
    return DifficultyParams.inverseInt(_difficulty.level, 10, 800, 3000);
  }

  // --- Getters ---

  int get gridSize => _gridSize;
  Set<int> get targetPattern => Set.unmodifiable(_targetPattern);
  Set<int> get tappedCells => Set.unmodifiable(_tappedCells);
  bool get isShowingPattern => _isShowingPattern;
  bool get isResponding => _isResponding;
  bool get isComplete => _isComplete;
  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;
  AdaptiveDifficulty get difficulty => _difficulty;
  double get accuracy => _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;

  /// Total cells in grid
  int get totalCells => _gridSize * _gridSize;

  /// Generate a new random target pattern
  Set<int> generatePattern() {
    _gridSize = gridSizeForLevel(_difficulty.level);
    _tappedCells = {};
    _isShowingPattern = true;
    _isResponding = false;

    final cellCount = totalCells;
    final fillCount = patternFillCount;
    _targetPattern = {};

    final indices = List.generate(cellCount, (i) => i);
    indices.shuffle(_random);

    for (int i = 0; i < fillCount && i < cellCount; i++) {
      _targetPattern.add(indices[i]);
    }

    return Set.unmodifiable(_targetPattern);
  }

  void startResponsePhase() {
    _isShowingPattern = false;
    _isResponding = true;
  }

  void toggleCell(int cellIndex) {
    if (!_isResponding || _isComplete) return;
    if (_tappedCells.contains(cellIndex)) {
      _tappedCells.remove(cellIndex);
    } else {
      _tappedCells.add(cellIndex);
    }
  }

  /// Check response against target pattern
  bool checkResponse() {
    _totalTrials++;
    final correct = Set<int>.from(_tappedCells)
        .containsAll(_targetPattern) &&
        _targetPattern.containsAll(_tappedCells);

    if (correct) {
      _handleSuccess();
    } else {
      _handleFailure();
    }

    return correct;
  }

  void _handleSuccess() {
    _totalCorrect++;
    _failsAtCurrentSize = 0;
    _difficulty.recordResult(true);
    _gridSize = gridSizeForLevel(_difficulty.level);
  }

  void _handleFailure() {
    _failsAtCurrentSize++;
    _difficulty.recordResult(false);

    if (_failsAtCurrentSize >= 2) {
      _isComplete = true;
    }
  }

  void skipToNext() {
    _handleFailure();
  }

  Map<String, dynamic> toSessionData() {
    final diffData = _difficulty.toJson();
    return {
      'task_id': 'grid_memory',
      'timestamp': DateTime.now().toIso8601String(),
      'grid_size': _gridSize,
      'total_trials': _totalTrials,
      'total_correct': _totalCorrect,
      'accuracy': accuracy,
      'child_age': childAge,
      ...diffData,
    };
  }
}

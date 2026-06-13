/// Corsi Block-Tapping Task (Memory Module)
/// Game 1: 记忆小路
///
/// Measures visuospatial working memory span.
/// Child watches blocks flash in sequence, then taps them in same order.
/// Reverse mode at higher difficulty levels.
/// Uses AdaptiveDifficulty for automatic leveling.

import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

class CorsiTask {
  final int childAge;
  final Random _random = Random();

  /// Adaptive difficulty — drives span, flash speed, reverse mode
  final AdaptiveDifficulty _difficulty;

  // 9 block positions in irregular layout (normalized 0-1)
  static const List<BlockPos> blockPositions = [
    BlockPos(0.2, 0.25),
    BlockPos(0.5, 0.1),
    BlockPos(0.8, 0.25),
    BlockPos(0.1, 0.45),
    BlockPos(0.5, 0.35),
    BlockPos(0.9, 0.5),
    BlockPos(0.25, 0.7),
    BlockPos(0.5, 0.65),
    BlockPos(0.75, 0.8),
  ];

  // State
  int _currentSpan = 2;
  int _maxSpan = 2;
  List<int> _currentSequence = [];
  int _flashIndex = -1;
  bool _isShowingSequence = false;
  bool _isResponding = false;
  int _failsAtCurrentSpan = 0;
  bool _isComplete = false;
  int _totalTrials = 0;
  int _totalCorrect = 0;
  final List<int> _responseSequence = [];

  CorsiTask({
    required this.childAge,
    AdaptiveDifficulty? difficulty,
  }) : _difficulty = difficulty ??
            AdaptiveDifficulty(
              gameId: 'corsi',
              maxLevel: 255,
              startLevel: _startLevelForAge(6),
            ) {
    _currentSpan = spanForLevel(_difficulty.level);
    _maxSpan = _currentSpan;
  }

  static int _startLevelForAge(int age) {
    return (age * 14).clamp(20, 200);
  }

  // --- Difficulty-driven parameters ---

  int get difficultyLevel => _difficulty.level;
  int get maxLevel => _difficulty.maxLevel;

  /// Span grows with level: [2→7] mapped from level [1→10]
  static int spanForLevel(int level) {
    return DifficultyParams.levelToInt(level, 10, 2, 7).clamp(2, 9);
  }

  /// Flash duration: shorter at higher levels
  int get flashDurationMs {
    return DifficultyParams.inverseInt(_difficulty.level, 10, 300, 800);
  }

  /// Interval between flashes
  int get flashIntervalMs {
    return DifficultyParams.inverseInt(_difficulty.level, 10, 150, 350);
  }

  /// Reverse mode kicks in at level 6+
  bool get reverseMode => _difficulty.level >= 6;

  // --- Getters ---

  int get currentSpan => _currentSpan;
  int get maxSpan => _maxSpan;
  int get flashIndex => _flashIndex;
  bool get isShowingSequence => _isShowingSequence;
  bool get isResponding => _isResponding;
  bool get isComplete => _isComplete;
  List<int> get currentSequence => List.unmodifiable(_currentSequence);
  List<int> get responseSequence => List.unmodifiable(_responseSequence);
  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;
  AdaptiveDifficulty get difficulty => _difficulty;
  double get accuracy =>
      _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;

  /// Start a new span level
  List<int> generateSequence() {
    _currentSpan = spanForLevel(_difficulty.level);
    _currentSequence = [];
    for (int i = 0; i < _currentSpan; i++) {
      int block;
      int tries = 0;
      do {
        block = _random.nextInt(9);
        tries++;
      } while (_currentSequence.contains(block) &&
               _currentSpan <= 9 &&
               tries < 50);
      _currentSequence.add(block);
    }
    _responseSequence.clear();
    _flashIndex = -1;
    _isShowingSequence = true;
    _isResponding = false;
    return List.unmodifiable(_currentSequence);
  }

  void advanceFlash(int index) {
    _flashIndex = index;
  }

  void startResponsePhase() {
    _isShowingSequence = false;
    _isResponding = true;
  }

  /// Returns true if this tap completes the sequence
  bool recordTap(int blockIndex) {
    if (!_isResponding) return false;
    _responseSequence.add(blockIndex);
    return _responseSequence.length >= _currentSpan;
  }

  /// Check if response matches expected sequence
  bool checkResponse() {
    _totalTrials++;
    final expected = reverseMode
        ? _currentSequence.reversed.toList()
        : _currentSequence;

    if (_responseSequence.length != expected.length) {
      _handleFailure();
      return false;
    }

    for (int i = 0; i < expected.length; i++) {
      if (_responseSequence[i] != expected[i]) {
        _handleFailure();
        return false;
      }
    }

    _handleSuccess();
    return true;
  }

  void _handleSuccess() {
    _totalCorrect++;
    _failsAtCurrentSpan = 0;
    _maxSpan = max(_maxSpan, _currentSpan);
    _difficulty.recordResult(true);

    // Refresh span from new level
    _currentSpan = spanForLevel(_difficulty.level);
  }

  void _handleFailure() {
    _failsAtCurrentSpan++;
    _difficulty.recordResult(false);

    if (_failsAtCurrentSpan >= 2) {
      _isComplete = true;
    }
  }

  void skipToNext() {
    _handleFailure();
  }

  Map<String, dynamic> toSessionData() {
    final diffData = _difficulty.toJson();
    return {
      'task_id': 'corsi',
      'timestamp': DateTime.now().toIso8601String(),
      'max_span': _maxSpan,
      'final_span': _currentSpan,
      'total_trials': _totalTrials,
      'total_correct': _totalCorrect,
      'accuracy': accuracy,
      'reverse_mode_used': reverseMode,
      'child_age': childAge,
      ...diffData,
    };
  }
}

class BlockPos {
  final double x;
  final double y;
  const BlockPos(this.x, this.y);
}

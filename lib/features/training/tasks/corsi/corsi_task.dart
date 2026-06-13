import 'dart:math';
import '../../../../core/utils/constants.dart';

/// Corsi Block-Tapping Task
/// Measures visuospatial working memory span
/// Child watches blocks flash in sequence, then taps them in the same order

class CorsiTask {
  final int childAge;
  final Random _random = Random();
  final bool reverseMode;

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
  int _flashIndex = -1; // which block is currently flashing
  bool _isShowingSequence = false; // true during flash phase
  bool _isResponding = false; // true during tap-back phase
  int _failsAtCurrentSpan = 0;
  bool _isComplete = false;
  int _totalTrials = 0;
  int _totalCorrect = 0;
  final List<int> _responseSequence = [];

  CorsiTask({required this.childAge, this.reverseMode = false});

  // Getters
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

  /// Start a new span level
  List<int> generateSequence() {
    _currentSequence = [];
    for (int i = 0; i < _currentSpan; i++) {
      int block;
      do {
        block = _random.nextInt(9);
      } while (_currentSequence.contains(block) &&
               _currentSpan <= 9); // allow repeats for max span
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
    if (_currentSpan < TrainingConstants.corsiMaxSpan) {
      _currentSpan++;
    }
  }

  void _handleFailure() {
    _failsAtCurrentSpan++;
    if (_failsAtCurrentSpan >= 2) {
      _isComplete = true;
    }
  }

  void skipToNext() {
    // Skip current (used when user gives up or timeout)
    _handleFailure();
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': reverseMode ? 'corsi_reverse' : 'corsi',
        'timestamp': DateTime.now().toIso8601String(),
        'max_span': _maxSpan,
        'final_span': _currentSpan,
        'total_trials': _totalTrials,
        'total_correct': _totalCorrect,
        'accuracy': _totalTrials > 0 ? _totalCorrect / _totalTrials : 0,
        'reverse_mode': reverseMode,
        'child_age': childAge,
      };
}

class BlockPos {
  final double x;
  final double y;
  const BlockPos(this.x, this.y);
}

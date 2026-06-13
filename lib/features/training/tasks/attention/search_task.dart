import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Visual Search Task — "火眼金睛"
/// Player must find a target emoji hidden among many distractor emojis.
///
/// Difficulty: higher level → more items, shorter time limit.

// Target emojis that can be searched for
const List<String> _searchTargets = [
  '🌟', '❤️', '🎈', '🍎', '⚽', '🌸', '🦋', '🎵',
  '🍕', '🌈', '🚀', '🦄', '🎪', '🐧', '🍭', '🌻',
];

// Distractor emoji pool
const List<String> _searchDistractors = [
  '⭐', '💛', '🎊', '🍊', '🏀', '🌺', '🐛', '🎶',
  '🍔', '☁️', '✈️', '🐴', '🎠', '🐤', '🍬', '🌿',
  '💫', '🧡', '🎉', '🍋', '🏈', '🌷', '🐞', '🎹',
  '🌮', '⛅', '🚁', '🦓', '🎡', '🦆', '🍫', '🌵',
  '✨', '💚', '🎀', '🍇', '🎾', '🌼', '🐝', '🥁',
  '🍩', '🌤️', '🛸', '🐎', '🎢', '🦉', '🧁', '🍀',
  '💥', '💜', '🎁', '🍓', '⚾', '🌻', '🦗', '🎷',
];

class SearchTask {
  final int childAge;
  final Random _random = Random();

  final AdaptiveDifficulty _difficulty;

  // --- Level-derived parameters ---
  late int _gridSize;       // 3..6 (level 1→10)
  late int _timeLimitMs;    // shorter at higher levels

  // --- State ---
  final int _totalRounds;
  int _currentRound = 0;

  // --- Current trial ---
  String _targetEmoji = '';
  List<String> _gridItems = [];
  int _targetIndex = 0;
  int _trialStartMs = 0;
  bool _responded = false;

  // --- Metrics ---
  int _hits = 0;
  int _misses = 0;
  int _errors = 0;
  final List<int> _reactionTimes = [];

  SearchTask({
    required this.childAge,
    int startLevel = 50,
    int totalRounds = 12,
  })  : _difficulty = AdaptiveDifficulty(
          gameId: 'attention_search',
          maxLevel: 255,
          startLevel: startLevel,
        ),
        _totalRounds = totalRounds {
    _applyLevelParams();
  }

  // --- Getters ---

  int get level => _difficulty.level;
  int get gridSize => _gridSize;
  int get timeLimitMs => _timeLimitMs;
  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  bool get isComplete => _currentRound >= _totalRounds;
  double get progress => _currentRound / _totalRounds;

  String get targetEmoji => _targetEmoji;
  List<String> get gridItems => List.unmodifiable(_gridItems);
  int get targetIndex => _targetIndex;

  int get hits => _hits;
  int get misses => _misses;
  int get errors => _errors;

  double get accuracy =>
      (_hits + _misses + _errors) > 0
          ? _hits / (_hits + _misses + _errors)
          : 0;

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  // --- Level param mapping ---

  void _applyLevelParams() {
    final lvl = _difficulty.level;
    _gridSize = DifficultyParams.levelToInt(lvl, 10, 3, 6);
    _timeLimitMs = DifficultyParams.inverseInt(lvl, 10, 5000, 15000);
  }

  // --- Trial lifecycle ---

  /// Generate a new search grid.
  /// Returns the target emoji so the UI can show a preview.
  void startNextTrial() {
    if (isComplete) return;

    _currentRound++;
    _targetEmoji = _searchTargets[_random.nextInt(_searchTargets.length)];

    final totalItems = _gridSize * _gridSize;
    _gridItems = List.filled(totalItems, '');

    // Pick distractors (excluding ones too similar to target)
    final distractorPool = List.of(_searchDistractors)
      ..shuffle(_random);

    _targetIndex = _random.nextInt(totalItems);

    for (var i = 0; i < totalItems; i++) {
      if (i == _targetIndex) {
        _gridItems[i] = _targetEmoji;
      } else {
        _gridItems[i] = distractorPool[i % distractorPool.length];
      }
    }

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
    _responded = false;
  }

  /// Player tapped item at [index].
  SearchResult recordResponse(int index) {
    if (_responded) return SearchResult.alreadyResponded;
    _responded = true;

    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;

    if (index == _targetIndex) {
      _hits++;
      _reactionTimes.add(rt);
      _difficulty.recordResult(true);
      return SearchResult.hit;
    } else {
      _errors++;
      _difficulty.recordResult(false);
      return SearchResult.error;
    }
  }

  /// Time ran out without finding the target.
  void recordTimeout() {
    if (_responded) return;
    _responded = true;
    _misses++;
    _difficulty.recordResult(false);
  }

  /// Re-read level and update grid params.
  void syncDifficultyParams() {
    _applyLevelParams();
  }

  // --- Session data ---

  Map<String, dynamic> toSessionData() => {
        'task_id': 'attention_search',
        'timestamp': DateTime.now().toIso8601String(),
        'total_rounds': _totalRounds,
        'completed_rounds': _currentRound,
        'hits': _hits,
        'misses': _misses,
        'errors': _errors,
        'accuracy': accuracy,
        'mean_rt': meanReactionTime,
        'level': _difficulty.level,
        'grid_size': _gridSize,
        'time_limit_ms': _timeLimitMs,
        'difficulty': _difficulty.toJson(),
      };
}

enum SearchResult { hit, error, alreadyResponded }

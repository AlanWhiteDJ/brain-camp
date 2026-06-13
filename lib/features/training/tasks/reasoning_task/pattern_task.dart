import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Pattern Completion Task — "找规律"
///
/// The child sees a sequence with one missing element (❓) and must
/// pick the item that completes the pattern.
///
/// Difficulty scales pattern complexity:
///   L1-2  → AB only
///   L3-4  → AB, AABB
///   L5-6  → AB, AABB, ABC
///   L7-8  → AB, AABB, ABC, ABB, ABA
///   L9-10 → All patterns including ABBC, ABCA, AABC

class PatternTask {
  final AdaptiveDifficulty difficulty;
  final Random _random = Random();

  static const int totalTrials = 20;

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];
  int _trialStartMs = 0;

  // Current trial
  PatternType _currentType = PatternType.ab;
  List<String> _sequence = [];
  List<String> _options = [];
  String _correctAnswer = '';
  int _correctOptionIndex = -1;

  PatternTask({required this.difficulty});

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  int get level => difficulty.level;
  List<String> get sequence => List.unmodifiable(_sequence);
  List<String> get options => List.unmodifiable(_options);
  int get correctOptionIndex => _correctOptionIndex;
  String get correctAnswer => _correctAnswer;

  List<PatternType> _availablePatterns() {
    final lv = difficulty.level;
    if (lv <= 2) return [PatternType.ab];
    if (lv <= 4) return [PatternType.ab, PatternType.aabb];
    if (lv <= 6) return [PatternType.ab, PatternType.aabb, PatternType.abc];
    if (lv <= 8) return [PatternType.ab, PatternType.aabb, PatternType.abc, PatternType.abb, PatternType.aba];
    return PatternType.values;
  }

  void nextTrial() {
    if (_isComplete) return;

    final types = _availablePatterns();
    _currentType = types[_random.nextInt(types.length)];

    // Generate sequence and correct answer
    switch (_currentType) {
      case PatternType.ab:
        _generateAB();
        break;
      case PatternType.aabb:
        _generateAABB();
        break;
      case PatternType.abc:
        _generateABC();
        break;
      case PatternType.abb:
        _generateABB();
        break;
      case PatternType.aba:
        _generateABA();
        break;
      case PatternType.abbc:
        _generateABBC();
        break;
      case PatternType.abca:
        _generateABCA();
        break;
      case PatternType.aabc:
        _generateAABC();
        break;
    }

    // Generate options: 1 correct + 3 distractors
    final base = _getBaseItems();
    final distractors = base.where((e) => e != _correctAnswer).toList()..shuffle(_random);
    _options = [_correctAnswer, ...distractors.take(3)];
    _options.shuffle(_random);
    _correctOptionIndex = _options.indexOf(_correctAnswer);

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  // ─── Pattern generators ──────────────────────────────────────────

  void _generateAB() {
    final items = _pick(2);
    // 🍎 🍊 🍎 🍊 ❓ → 🍎
    _sequence = [items[0], items[1], items[0], items[1], '❓'];
    _correctAnswer = items[0];
  }

  void _generateAABB() {
    final items = _pick(2);
    // 🍎 🍎 🍊 🍊 ❓ → 🍎
    _sequence = [items[0], items[0], items[1], items[1], '❓'];
    _correctAnswer = items[0];
  }

  void _generateABC() {
    final items = _pick(3);
    // 🍎 🍊 🍋 🍎 🍊 ❓ → 🍋
    _sequence = [items[0], items[1], items[2], items[0], items[1], '❓'];
    _correctAnswer = items[2];
  }

  void _generateABB() {
    final items = _pick(2);
    // 🍎 🍊 🍊 🍎 ❓ → 🍊
    _sequence = [items[0], items[1], items[1], items[0], '❓'];
    _correctAnswer = items[1];
  }

  void _generateABA() {
    final items = _pick(2);
    // 🍎 🍊 🍎 🍊 ❓ → 🍎
    _sequence = [items[0], items[1], items[0], items[1], '❓'];
    _correctAnswer = items[0];
  }

  void _generateABBC() {
    final items = _pick(3);
    // 🍎 🍊 🍊 🍋 🍎 ❓ → 🍊
    _sequence = [items[0], items[1], items[1], items[2], items[0], '❓'];
    _correctAnswer = items[1];
  }

  void _generateABCA() {
    final items = _pick(3);
    // 🍎 🍊 🍋 🍎 🍊 ❓ → 🍋
    _sequence = [items[0], items[1], items[2], items[0], items[1], '❓'];
    _correctAnswer = items[2];
  }

  void _generateAABC() {
    final items = _pick(3);
    // 🍎 🍎 🍊 🍋 🍎 ❓ → 🍎
    _sequence = [items[0], items[0], items[1], items[2], items[0], '❓'];
    _correctAnswer = items[0];
  }

  List<String> _pick(int n) {
    final pool = _getBaseItems()..shuffle(_random);
    return pool.take(n).toList();
  }

  /// Pool of kid-friendly emoji items
  List<String> _getBaseItems() => [
        '🍎', '⭐', '🌙', '🌸', '🎈', '🐱', '🐶', '🐰', '🍊', '🍇',
        '❤️', '🎵', '☀️', '🌈', '🦋', '🐟', '🍓', '🍌', '🎀', '⚽',
      ];

  bool checkAnswer(String chosen) {
    _trialCount++;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = _options[_correctOptionIndex] == chosen;
    if (correct) _correctCount++;
    difficulty.recordResult(correct);
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reasoning_pattern',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'final_level': difficulty.level,
        'difficulty': difficulty.toJson(),
      };
}

enum PatternType { ab, aabb, abc, abb, aba, abbc, abca, aabc }

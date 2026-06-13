import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Odd One Out Task — "找不同"
///
/// The child sees several items; all but one share a category.
/// They must tap the one that doesn't belong.
///
/// Difficulty scales:
///   L1-3  → 4 items, obvious different category
///   L4-6  → 5 items, subtler differences
///   L7-8  → 6 items, closer categories
///   L9-10 → 6 items, very subtle (same super-category, different sub)

class OddOneTask {
  final AdaptiveDifficulty difficulty;
  final Random _random = Random();

  static const int totalTrials = 20;

  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];
  int _trialStartMs = 0;

  // Current trial
  List<String> _items = [];
  int _oddIndex = -1;
  String _categoryHint = '';

  OddOneTask({required this.difficulty});

  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  int get level => difficulty.level;
  List<String> get items => List.unmodifiable(_items);
  int get oddIndex => _oddIndex;
  String get categoryHint => _categoryHint;

  int get itemCount {
    final lv = difficulty.level;
    if (lv <= 3) return 4;
    if (lv <= 6) return 5;
    return 6;
  }

  /// Category pools — each entry: (category_name, [emoji_items])
  static const List<_CategoryPool> _pools = [
    // Super-category: Animals
    _CategoryPool('动物', ['🐱', '🐶', '🐰', '🐻', '🐼', '🐨', '🦊', '🐸', '🐵', '🐮', '🐷', '🐔']),
    // Super-category: Fruits
    _CategoryPool('水果', ['🍎', '🍊', '🍇', '🍓', '🍌', '🍑', '🍒', '🥝', '🍉', '🍋', '🍐', '🥭']),
    // Super-category: Vehicles
    _CategoryPool('交通工具', ['🚗', '🚌', '🚲', '✈️', '🚢', '🚁', '🚂', '🛵', '🏍️', '🚜', '⛵', '🚀']),
    // Super-category: Food
    _CategoryPool('食物', ['🍕', '🍔', '🌭', '🍟', '🍩', '🍪', '🎂', '🍿', '🧁', '🥞', '🍦', '🧀']),
    // Super-category: Body parts
    _CategoryPool('身体部位', ['👀', '👃', '👄', '👂', '🦶', '👋', '💪', '🦷', '👅', '🧠', '🫀', '🦵']),
    // Super-category: Clothes
    _CategoryPool('衣服', ['👕', '👖', '👗', '🧢', '🧣', '🧤', '👟', '👒', '🩳', '🧥', '👚', '🩱']),
    // Super-category: Weather/Nature
    _CategoryPool('天气', ['☀️', '🌧️', '⛈️', '❄️', '🌈', '🌪️', '☁️', '🌤️', '🌨️', '⚡', '💨', '🌫️']),
    // Super-category: Sports
    _CategoryPool('运动', ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓', '🎱', '🥊', '🏸', '⛳', '🛹']),
    // Super-category: Musical Instruments
    _CategoryPool('乐器', ['🎸', '🥁', '🎹', '🎺', '🎻', '🪕', '🎷', '🪘', '🎵', '🔔', '🎼', '🪇']),
    // Super-category: School
    _CategoryPool('学校用品', ['📚', '✏️', '📏', '🎒', '📐', '🖍️', '📎', '📓', '🖊️', '📌', '✂️', '📋']),
    // Super-category: Plants/Flowers
    _CategoryPool('植物', ['🌻', '🌹', '🌺', '🌸', '🌷', '💐', '🌼', '🪷', '🌾', '🍀', '🌿', '🪴']),
    // Super-category: Colors (abstract)
    _CategoryPool('颜色', ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠', '🟤', '⚫', '⚪', '🔶', '🔷', '🩷']),
  ];

  // Sub-category pools for high difficulty (level 7+)
  static const List<_CategoryPool> _subPools = [
    _CategoryPool('水里动物', ['🐟', '🐠', '🐡', '🦈', '🐳', '🐬', '🦀', '🐙', '🦑', '🦞', '🐚', '🦭']),
    _CategoryPool('会飞动物', ['🐦', '🦅', '🦉', '🦜', '🕊️', '🦆', '🦢', '🦩', '🐧', '🦇', '🦋', '🐝']),
    _CategoryPool('红色水果', ['🍎', '🍒', '🍓', '🍉', '🌶️', '🍅', '🧧', '🫐']),
    _CategoryPool('黄色水果', ['🍌', '🍋', '🍍', '🍑', '🌽', '🍊', '🥭', '⭐']),
    _CategoryPool('地面交通', ['🚗', '🚌', '🚲', '🏍️', '🚂', '🛵', '🚜', '🚛']),
    _CategoryPool('空中交通', ['✈️', '🚁', '🛩️', '🎈', '🪁', '🚀', '🛸', '🦅']),
  ];

  void nextTrial() {
    if (_isComplete) return;

    final lv = difficulty.level;
    final n = itemCount;

    _CategoryPool pool;

    if (lv >= 7) {
      // High difficulty: same super-category, different sub-category
      // Pick two sub-pools; items from one pool, odd from another
      final subPools = _subPools..shuffle(_random);
      pool = subPools[0];
      final oddPool = subPools[1];
      final poolItems = List<String>.from(pool.items)..shuffle(_random);
      final oddItems = List<String>.from(oddPool.items)..shuffle(_random);

      _items = [...poolItems.take(n - 1), oddItems.first];
      _categoryHint = '这些${pool.name}中有一个不一样';
    } else if (lv >= 4) {
      // Medium: different category, but closer categories
      final pools = _pools..shuffle(_random);
      pool = pools[0];
      final oddPool = pools[1];
      final poolItems = List<String>.from(pool.items)..shuffle(_random);
      final oddItems = List<String>.from(oddPool.items)..shuffle(_random);

      _items = [...poolItems.take(n - 1), oddItems.first];
      _categoryHint = '大部分是${pool.name}';
    } else {
      // Easy: very different categories
      final pools = _pools..shuffle(_random);
      pool = pools[0];
      // Pick odd from a very different pool (skip index 0,1 to get different categories)
      final oddPool = pools[3 + _random.nextInt(pools.length - 3)];
      final poolItems = List<String>.from(pool.items)..shuffle(_random);
      final oddItems = List<String>.from(oddPool.items)..shuffle(_random);

      _items = [...poolItems.take(n - 1), oddItems.first];
      _categoryHint = '大部分是${pool.name}，有一个不是';
    }

    _items.shuffle(_random);
    _oddIndex = _items.indexWhere((e) => !pool.items.contains(e));
    if (_oddIndex == -1) {
      // Fallback: last item is the odd one
      _oddIndex = n - 1;
    }

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  bool checkAnswer(int chosenIndex) {
    _trialCount++;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = chosenIndex == _oddIndex;
    if (correct) _correctCount++;
    difficulty.recordResult(correct);
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reasoning_oddone',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'final_level': difficulty.level,
        'difficulty': difficulty.toJson(),
      };
}

class _CategoryPool {
  final String name;
  final List<String> items;
  const _CategoryPool(this.name, this.items);
}

class TrainingConstants {
  // CPT task defaults
  static const int cptDefaultDurationMs = 120000; // 2 minutes
  static const int cptMinDurationMs = 90000;
  static const int cptMaxDurationMs = 180000;
  static const double cptTargetProbability = 0.20; // 20% targets
  static const int cptDefaultIntervalMs = 1500; // between stimuli
  static const int cptMinIntervalMs = 800;
  static const int cptMaxIntervalMs = 2000;

  // Corsi task defaults
  static const int corsiMinSpan = 2;
  static const int corsiMaxSpan = 9;
  static const int corsiFlashDurationMs = 800;
  static const int corsiFlashIntervalMs = 300;

  // Reaction task defaults
  static const int rtDefaultTrials = 30;
  static const int rtMinIntervalMs = 1000;
  static const int rtMaxIntervalMs = 4000;
  static const int rtTimeoutMs = 3000;
  static const int rtMinValidMs = 100; // below this is anticipation

  // Age group mappings
  static const Map<String, int> ageGroupMinutes = {
    '3-4': 2,
    '5-6': 2,
    '7-8': 3,
    '9-10': 3,
    '11-12': 4,
  };

  static List<String> get ageGroups => ageGroupMinutes.keys.toList();

  static int trainingDurationForAge(int age) {
    if (age <= 4) return 2;
    if (age <= 6) return 2;
    if (age <= 8) return 3;
    if (age <= 10) return 3;
    return 4;
  }
}

// Animals used in CPT training
const List<String> cptAnimals = ['🐱', '🐶', '🐰', '🐻', '🦊', '🐸', '🐵', '🐮'];
const String cptTargetAnimal = '🐑'; // sheep is the target

// Colors for training tasks
const List<int> taskColors = [
  0xFFEF5350, // red
  0xFF42A5F5, // blue
  0xFFFFCA28, // yellow
  0xFF66BB6A, // green
  0xFFAB47BC, // purple
  0xFFFF7043, // orange
  0xFF26C6DA, // cyan
  0xFFEC407A, // pink
];

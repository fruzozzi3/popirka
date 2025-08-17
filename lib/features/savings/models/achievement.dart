// lib/features/achievements/models/achievement.dart
enum AchievementType {
  firstDeposit,
  reach1000,
  reach5000,
  reach10000,
  reach50000,
  reach100000,
  streak7days,
  streak30days,
  completedGoal,
  bigSaver, // за одно пополнение больше 5000
  consistent, // пополнения каждый день в течение недели
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.maxProgress = 1,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return Achievement(
      type: type,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress,
    );
  }

  double get progressPercent => maxProgress > 0 ? progress / maxProgress : 0.0;

  static List<Achievement> getAllAchievements() {
    return [
      Achievement(
        type: AchievementType.firstDeposit,
        title: 'Первые деньги',
        description: 'Сделай первое пополнение',
        icon: '💰',
      ),
      Achievement(
        type: AchievementType.reach1000,
        title: 'Первая тысяча',
        description: 'Накопи 1 000 ₽',
        icon: '🎯',
        maxProgress: 1000,
      ),
      Achievement(
        type: AchievementType.reach5000,
        title: 'Серьезные накопления',
        description: 'Накопи 5 000 ₽',
        icon: '💎',
        maxProgress: 5000,
      ),
      Achievement(
        type: AchievementType.reach10000,
        title: 'Десятка',
        description: 'Накопи 10 000 ₽',
        icon: '👑',
        maxProgress: 10000,
      ),
      Achievement(
        type: AchievementType.reach50000,
        title: 'Солидная сумма',
        description: 'Накопи 50 000 ₽',
        icon: '🏆',
        maxProgress: 50000,
      ),
      Achievement(
        type: AchievementType.reach100000,
        title: 'Сто тысяч!',
        description: 'Накопи 100 000 ₽',
        icon: '🚀',
        maxProgress: 100000,
      ),
      Achievement(
        type: AchievementType.streak7days,
        title: 'Неделя дисциплины',
        description: 'Пополняй копилку 7 дней подряд',
        icon: '🔥',
        maxProgress: 7,
      ),
      Achievement(
        type: AchievementType.streak30days,
        title: 'Месяц постоянства',
        description: 'Пополняй копилку 30 дней подряд',
        icon: '⚡',
        maxProgress: 30,
      ),
      Achievement(
        type: AchievementType.completedGoal,
        title: 'Цель достигнута',
        description: 'Выполни свою первую цель',
        icon: '✅',
      ),
      Achievement(
        type: AchievementType.bigSaver,
        title: 'Большие вклады',
        description: 'Пополни копилку на 5 000 ₽ за раз',
        icon: '💪',
        maxProgress: 5000,
      ),
    ];
  }
}

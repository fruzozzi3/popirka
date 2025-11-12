// lib/features/savings/viewmodels/savings_view_model.dart
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:my_kopilka/features/savings/data/repository/savings_repository.dart';
import 'package:my_kopilka/features/savings/models/achievement.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/statistics.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart';

class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  SavingsViewModel(this._repository);

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    try {
      await fetchGoals();
    } catch (e) {
      debugPrint('Error initializing SavingsViewModel: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGoals() async {
    try {
      _isLoading = true;
      notifyListeners();

      final fetchedGoals = await _repository.getAllGoals();
      for (var goal in fetchedGoals) {
        goal.currentAmount = await _repository.getCurrentSumForGoal(goal.id!);
      }
      _goals = fetchedGoals;

      await _refreshAchievements();
    } catch (e) {
      debugPrint('Error fetching goals: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(String name, int targetAmount) async {
    try {
      final newGoal = Goal(
        name: name,
        targetAmount: targetAmount,
        createdAt: DateTime.now(),
      );
      await _repository.addGoal(newGoal);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error adding goal: $e');
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error updating goal: $e');
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await _repository.deleteGoal(goalId);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
    }
  }

  Future<void> addTransaction(int goalId, int amount, {String? notes}) async {
    try {
      final transaction = Transaction(
        goalId: goalId,
        amount: amount,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await _repository.addTransaction(transaction);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<List<Transaction>> getTransactionsForGoal(int goalId) async {
    try {
      return await _repository.getTransactionsForGoal(goalId);
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  Future<SavingsStatistics> getStatisticsForGoal(int goalId) async {
    try {
      final transactions = await getTransactionsForGoal(goalId);
      
      final deposits = transactions.where((t) => t.amount > 0).toList();
      final withdrawals = transactions.where((t) => t.amount < 0).toList();
      
      final totalDeposits = deposits.fold(0, (sum, t) => sum + t.amount);
      final totalWithdrawals = withdrawals.fold(0, (sum, t) => sum + t.amount.abs());
      
      return SavingsStatistics(
        totalDeposits: totalDeposits,
        totalWithdrawals: totalWithdrawals,
        netAmount: totalDeposits - totalWithdrawals,
        averageDeposit: deposits.isEmpty ? 0 : totalDeposits / deposits.length,
        averageWithdrawal: withdrawals.isEmpty ? 0 : totalWithdrawals / withdrawals.length,
        totalTransactions: transactions.length,
        firstTransaction: transactions.isEmpty ? null : transactions.last.createdAt,
        lastTransaction: transactions.isEmpty ? null : transactions.first.createdAt,
      );
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return SavingsStatistics();
    }
  }

  Future<void> _refreshAchievements() async {
    try {
      final transactions = await _repository.getAllTransactions();
      _achievements = _calculateAchievements(transactions);
    } catch (e) {
      debugPrint('Error updating achievements: $e');
    }
  }

  List<Achievement> _calculateAchievements(List<Transaction> transactions) {
    final baseAchievements = Achievement.getAllAchievements();
    if (baseAchievements.isEmpty) {
      return [];
    }

    final deposits = transactions
        .where((t) => t.amount > 0)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final totalSaved = getTotalSaved();
    final hasCompletedGoal = getCompletedGoals().isNotEmpty;
    final biggestDeposit = deposits.isEmpty
        ? 0
        : deposits.map((t) => t.amount).reduce(max);
    final longestStreak = _calculateLongestDepositStreak(deposits);

    return baseAchievements.map((achievement) {
      DateTime? unlockedAt;
      bool isUnlocked = false;
      int progress = 0;

      switch (achievement.type) {
        case AchievementType.firstDeposit:
          isUnlocked = deposits.isNotEmpty;
          progress = isUnlocked ? 1 : 0;
          unlockedAt = isUnlocked ? deposits.first.createdAt : null;
          break;
        case AchievementType.reach1000:
        case AchievementType.reach5000:
        case AchievementType.reach10000:
        case AchievementType.reach50000:
        case AchievementType.reach100000:
          final progress = min(totalSaved, achievement.maxProgress);
          isUnlocked = totalSaved >= achievement.maxProgress;
          unlockedAt = isUnlocked && deposits.isNotEmpty
              ? _findDepositDateForAmount(deposits, achievement.maxProgress)
              : null;
          return Achievement(
            type: achievement.type,
            title: achievement.title,
            description: achievement.description,
            icon: achievement.icon,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
            progress: progress,
            maxProgress: achievement.maxProgress,
          );
        case AchievementType.streak7days:
        case AchievementType.streak30days:
          progress = min(longestStreak, achievement.maxProgress);
          isUnlocked = longestStreak >= achievement.maxProgress;
          break;
        case AchievementType.completedGoal:
          isUnlocked = hasCompletedGoal;
          progress = isUnlocked ? 1 : 0;
          break;
        case AchievementType.bigSaver:
          final progress = min(biggestDeposit, achievement.maxProgress);
          isUnlocked = biggestDeposit >= achievement.maxProgress;
          unlockedAt = isUnlocked && deposits.isNotEmpty
              ? _findSingleDepositDate(deposits, achievement.maxProgress)
              : null;
          return Achievement(
            type: achievement.type,
            title: achievement.title,
            description: achievement.description,
            icon: achievement.icon,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
            progress: progress,
            maxProgress: achievement.maxProgress,
          );
        case AchievementType.consistent:
          // Нет отдельной карточки для этого достижения, поэтому просто возвращаем исходное значение
          return achievement;
      }
      return Achievement(
        type: achievement.type,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAt,
        progress: progress,
        maxProgress: achievement.maxProgress,
      );
    }).toList();
  }

  int _calculateLongestDepositStreak(List<Transaction> deposits) {
    if (deposits.isEmpty) return 0;

    final uniqueDates = deposits
        .map((t) => DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (var i = 1; i < uniqueDates.length; i++) {
      final difference = uniqueDates[i].difference(uniqueDates[i - 1]).inDays;
      if (difference == 0) {
        continue;
      }
      if (difference == 1) {
        current += 1;
      } else {
        current = 1;
      }
      longest = max(longest, current);
    }

    return longest;
  }

  DateTime? _findDepositDateForAmount(List<Transaction> deposits, int targetAmount) {
    int accumulated = 0;
    for (final transaction in deposits) {
      accumulated += transaction.amount;
      if (accumulated >= targetAmount) {
        return transaction.createdAt;
      }
    }
    return null;
  }

  DateTime? _findSingleDepositDate(List<Transaction> deposits, int targetAmount) {
    for (final transaction in deposits) {
      if (transaction.amount >= targetAmount) {
        return transaction.createdAt;
      }
    }
    return null;
  }

  // Мотивационные сообщения
  String getMotivationalMessage(Goal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    
    if (progress >= 1.0) {
      return "🎉 Поздравляем! Цель достигнута!";
    } else if (progress >= 0.9) {
      return "🔥 Почти готово! Осталось совсем чуть-чуть!";
    } else if (progress >= 0.75) {
      return "💪 Отличный прогресс! Продолжай в том же духе!";
    } else if (progress >= 0.5) {
      return "📈 Половина пути пройдена! Ты молодец!";
    } else if (progress >= 0.25) {
      return "🌟 Хорошее начало! Продолжай копить!";
    } else if (progress > 0) {
      return "🚀 Отличный старт! Каждый рубль приближает к цели!";
    } else {
      return "💡 Время начать копить! Первый шаг самый важный!";
    }
  }

  // Предсказания
  List<PredictionModel> getPredictions(Goal goal) {
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return [];

    final predictionAmounts = [50, 100, 200, 500, 1000];
    return predictionAmounts.map((daily) {
      final days = (remaining / daily).ceil();
      return PredictionModel(
        dailyAmount: daily,
        daysToGoal: days,
        estimatedDate: DateTime.now().add(Duration(days: days)),
      );
    }).toList();
  }

  // Дополнительные функции
  int getTotalSaved() {
    return _goals.fold(0, (sum, goal) => sum + goal.currentAmount);
  }

  int getTotalGoals() {
    return _goals.fold(0, (sum, goal) => sum + goal.targetAmount);
  }

  double getOverallProgress() {
    final total = getTotalGoals();
    final saved = getTotalSaved();
    return total > 0 ? saved / total : 0.0;
  }

  List<Goal> getCompletedGoals() {
    return _goals.where((g) => g.currentAmount >= g.targetAmount).toList();
  }

  List<Goal> getActiveGoals() {
    return _goals.where((g) => g.currentAmount < g.targetAmount).toList();
  }
}

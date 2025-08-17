// lib/features/savings/viewmodels/savings_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:my_kopilka/features/savings/data/repository/savings_repository.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart';
import 'package:my_kopilka/features/savings/models/statistics.dart';
import 'package:my_kopilka/features/achievements/models/achievement.dart';

class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  SavingsViewModel(this._repository);

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Achievement> _achievements = Achievement.getAllAchievements();
  List<Achievement> get achievements => _achievements;
  
  List<Achievement> get unlockedAchievements => 
      _achievements.where((a) => a.isUnlocked).toList();

  Future<void> init() async {
    await fetchGoals();
    await _updateAchievements();
  }

  Future<void> fetchGoals() async {
    _isLoading = true;
    notifyListeners();

    final fetchedGoals = await _repository.getAllGoals();
    for (var goal in fetchedGoals) {
      goal.currentAmount = await _repository.getCurrentSumForGoal(goal.id!);
    }
    _goals = fetchedGoals;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(String name, int targetAmount) async {
    final newGoal = Goal(
      name: name,
      targetAmount: targetAmount,
      createdAt: DateTime.now(),
    );
    await _repository.addGoal(newGoal);
    await fetchGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    await _repository.updateGoal(goal);
    await fetchGoals();
  }

  Future<void> deleteGoal(int goalId) async {
    await _repository.deleteGoal(goalId);
    await fetchGoals();
  }

  Future<void> addTransaction(int goalId, int amount, {String? notes}) async {
    final transaction = Transaction(
      goalId: goalId,
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _repository.addTransaction(transaction);
    await fetchGoals();
    await _updateAchievements();
  }

  Future<List<Transaction>> getTransactionsForGoal(int goalId) {
    return _repository.getTransactionsForGoal(goalId);
  }

  // Новые функции для статистики
  Future<SavingsStatistics> getStatisticsForGoal(int goalId) async {
    final transactions = await _repository.getTransactionsForGoal(goalId);
    final deposits = transactions.where((t) => t.amount > 0).toList();
    final withdrawals = transactions.where((t) => t.amount < 0).toList();
    
    final totalDeposits = deposits.fold<int>(0, (sum, t) => sum + t.amount);
    final totalWithdrawals = withdrawals.fold<int>(0, (sum, t) => sum + t.amount.abs());
    
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

  // Достижения
  Future<void> _updateAchievements() async {
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      final newAchievement = await _checkAchievement(achievement);
      if (newAchievement.isUnlocked != achievement.isUnlocked) {
        _achievements[i] = newAchievement;
      }
    }
    notifyListeners();
  }

  Future<Achievement> _checkAchievement(Achievement achievement) async {
    switch (achievement.type) {
      case AchievementType.firstDeposit:
        final hasDeposits = _goals.any((g) => g.currentAmount > 0);
        return achievement.copyWith(
          isUnlocked: hasDeposits,
          unlockedAt: hasDeposits ? DateTime.now() : null,
        );

      case AchievementType.reach1000:
      case AchievementType.reach5000:
      case AchievementType.reach10000:
      case AchievementType.reach50000:
      case AchievementType.reach100000:
        final maxAmount = _goals.isEmpty 
            ? 0 
            : _goals.

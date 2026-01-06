// lib/features/savings/viewmodels/savings_view_model.dart

import 'package:flutter/foundation.dart';
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

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      _achievements = Achievement.getAllAchievements();
      await fetchGoals();
    } catch (e) {
      debugPrint('Error initializing SavingsViewModel: $e');
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchGoals() async {
    _setLoading(true);
    try {
      final fetchedGoals = await _repository.getAllGoals();

      final sums = await Future.wait<int>(
        fetchedGoals.map((g) async {
          final id = g.id;
          if (id == null) return 0;
          return _repository.getCurrentSumForGoal(id);
        }),
      );

      for (var i = 0; i < fetchedGoals.length; i++) {
        fetchedGoals[i].currentAmount = sums[i];
      }

      _goals = fetchedGoals;
    } catch (e) {
      debugPrint('Error fetching goals: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
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
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await _repository.deleteGoal(goalId);
      await fetchGoals();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  Future<void> addTransaction(int goalId, int amount, {String? notes}) async {
    if (amount == 0) {
      throw ArgumentError.value(amount, 'amount', 'Amount must not be 0');
    }

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
      rethrow;
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

  // Мотивационные сообщения
  String getMotivationalMessage(Goal goal) {
    final target = goal.targetAmount;
    if (target <= 0) {
      return "💡 Задай сумму цели — и начнем копить!";
    }

    final progress = (goal.currentAmount / target).clamp(0.0, 1.5);

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
    if (goal.targetAmount <= 0) return [];

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
  int getTotalSaved() => _goals.fold(0, (sum, goal) => sum + goal.currentAmount);

  int getTotalGoals() => _goals.fold(0, (sum, goal) => sum + goal.targetAmount);

  double getOverallProgress() {
    final total = getTotalGoals();
    final saved = getTotalSaved();
    return total > 0 ? saved / total : 0.0;
  }

  List<Goal> getCompletedGoals() => _goals.where((g) => g.currentAmount >= g.targetAmount).toList();

  List<Goal> getActiveGoals() => _goals.where((g) => g.currentAmount < g.targetAmount).toList();
}

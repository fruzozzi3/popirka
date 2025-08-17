// lib/features/savings/viewmodels/savings_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:my_kopilka/features/savings/data/repository/savings_repository.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart';

class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _repository;
  SavingsViewModel(this._repository);

  List<Goal> _goals = [];
  List<Goal> get goals => _goals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await fetchGoals();
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
  }

  Future<List<Transaction>> getTransactionsForGoal(int goalId) {
    return _repository.getTransactionsForGoal(goalId);
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

// Временные модели
class PredictionModel {
  final int dailyAmount;
  final int daysToGoal;
  final DateTime estimatedDate;

  PredictionModel({
    required this.dailyAmount,
    required this.daysToGoal,
    required this.estimatedDate,
  });
}

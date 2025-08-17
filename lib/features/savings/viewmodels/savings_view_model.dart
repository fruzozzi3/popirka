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
    await fetchGoals(); // Обновляем цели, чтобы пересчитать суммы
  }

  Future<List<Transaction>> getTransactionsForGoal(int goalId) {
    return _repository.getTransactionsForGoal(goalId);
  }
}
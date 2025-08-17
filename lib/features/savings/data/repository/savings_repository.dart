// lib/features/savings/data/repository/savings_repository.dart

import 'package:my_kopilka/core/db/app_database.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart';

class SavingsRepository {
  final AppDatabase _appDatabase = AppDatabase();

  // --- GOALS ---
  Future<int> addGoal(Goal goal) async {
    final db = await _appDatabase.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await _appDatabase.database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await _appDatabase.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('goals', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }
  
  // --- TRANSACTIONS ---
  Future<void> addTransaction(Transaction transaction) async {
    final db = await _appDatabase.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getTransactionsForGoal(int goalId) async {
    final db = await _appDatabase.database;
    final res = await db.query(
      'transactions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'created_at DESC',
    );
    return res.map((e) => Transaction.fromMap(e)).toList();
  }

  Future<int> getCurrentSumForGoal(int goalId) async {
    final db = await _appDatabase.database;
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE goal_id = ?',
      [goalId],
    );
    final value = res.first['total'] as int?;
    return value ?? 0;
  }
}
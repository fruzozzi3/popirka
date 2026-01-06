// lib/features/savings/data/repository/savings_repository.dart

import 'package:my_kopilka/core/db/app_database.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart';

class SavingsRepository {
  final AppDatabase _appDatabase = AppDatabase();

  // --- GOALS ---
  Future<int> addGoal(Goal goal) async {
    final db = await _appDatabase.database;
    return db.insert('goals', goal.toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await _appDatabase.database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await _appDatabase.database;

    // Даже если CASCADE по какой-то причине не сработает — транзакции все равно удалятся
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'goal_id = ?', whereArgs: [id]);
      await txn.delete('goals', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await _appDatabase.database;
    final maps = await db.query('goals', orderBy: 'created_at DESC');
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

  Future<List<Transaction>> getAllTransactions() async {
    final db = await _appDatabase.database;
    final res = await db.query('transactions', orderBy: 'created_at DESC');
    return res.map((e) => Transaction.fromMap(e)).toList();
  }

  Future<int> getCurrentSumForGoal(int goalId) async {
    final db = await _appDatabase.database;
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE goal_id = ?',
      [goalId],
    );

    // SQLite SUM может вернуть int/double/null
    final num? value = res.first['total'] as num?;
    return value?.toInt() ?? 0;
  }
}

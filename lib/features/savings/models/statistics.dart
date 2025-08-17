// lib/features/savings/models/statistics.dart
class SavingsStatistics {
  final int totalDeposits;
  final int totalWithdrawals;
  final int netAmount;
  final double averageDeposit;
  final double averageWithdrawal;
  final int totalTransactions;
  final DateTime? firstTransaction;
  final DateTime? lastTransaction;
  final Map<int, int> monthlyDeposits; // месяц -> сумма
  final List<DailyAmount> dailyAmounts; // для графика
  final int daysToGoal;
  final Map<String, int> achievementsCount;

  SavingsStatistics({
    this.totalDeposits = 0,
    this.totalWithdrawals = 0,
    this.netAmount = 0,
    this.averageDeposit = 0,
    this.averageWithdrawal = 0,
    this.totalTransactions = 0,
    this.firstTransaction,
    this.lastTransaction,
    this.monthlyDeposits = const {},
    this.dailyAmounts = const [],
    this.daysToGoal = 0,
    this.achievementsCount = const {},
  });
}

class DailyAmount {
  final DateTime date;
  final int amount;

  DailyAmount({required this.date, required this.amount});
}

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

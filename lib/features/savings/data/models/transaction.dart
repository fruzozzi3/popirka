// lib/features/savings/data/models/transaction.dart

class Transaction {
  final int? id;
  final int goalId;
  final int amount; // Положительное - пополнение, отрицательное - снятие
  final String? notes;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.goalId,
    required this.amount,
    this.notes,
    required this.createdAt,
  });

   Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'amount': amount,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as int?,
        goalId: map['goal_id'] as int,
        amount: map['amount'] as int,
        notes: map['notes'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
// lib/features/savings/data/models/goal.dart

class Goal {
  final int? id;
  final String name;
  final int targetAmount;
  final DateTime createdAt;
  // Это поле будет вычисляться отдельно и не хранится в БД
  int currentAmount;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.currentAmount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetAmount: map['target_amount'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
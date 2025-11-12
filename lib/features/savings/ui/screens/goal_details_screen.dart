import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart' as model;
import 'package:my_kopilka/features/savings/ui/screens/statistics_screen.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:provider/provider.dart';

class GoalDetailsScreen extends StatefulWidget {
  final int goalId;
  const GoalDetailsScreen({super.key, required this.goalId});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late Future<List<model.Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<SavingsViewModel>(context, listen: false);
    _transactionsFuture = vm.getTransactionsForGoal(widget.goalId);
  }

  void _loadTransactions() {
    final vm = Provider.of<SavingsViewModel>(context, listen: false);
    setState(() {
      _transactionsFuture = vm.getTransactionsForGoal(widget.goalId);
    });
  }

  void _showAddTransactionDialog(BuildContext context, {required bool isWithdrawal}) {
    final vm = context.read<SavingsViewModel>();
    final goal = vm.goals.firstWhere((g) => g.id == widget.goalId);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWithdrawal ? 'Снять из копилки' : 'Пополнить копилку'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Сумма'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) return 'Введите сумму';
                  final parsedAmount = int.tryParse(value);
                  if (parsedAmount == null || parsedAmount <= 0) return 'Сумма должна быть больше нуля';
                  if (isWithdrawal && parsedAmount > goal.currentAmount) {
                    return 'Нельзя снять больше, чем накоплено (${currencyFormat.format(goal.currentAmount)})';
                  }
                  return null;
                },
              ),
              if (isWithdrawal)
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'На что (необязательно)'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                int amount = int.parse(amountController.text);
                if (isWithdrawal) {
                  amount = -amount; // Делаем сумму отрицательной для снятия
                }
                final notes = notesController.text.isNotEmpty ? notesController.text : null;
                
                vm.addTransaction(widget.goalId, amount, notes: notes).then((_) {
                  Navigator.of(context).pop();
                  _loadTransactions(); // Перезагружаем список транзакций
                });
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context) {
    final vm = context.read<SavingsViewModel>();
    final goal = vm.goals.firstWhere((g) => g.id == widget.goalId);
    final nameController = TextEditingController(text: goal.name);
    final amountController = TextEditingController(text: goal.targetAmount.toString());
    final formKey = GlobalKey<FormState>();
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать цель'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название цели'),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма цели',
                  suffixText: '₽',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Введите сумму';
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Сумма должна быть положительной';
                  if (parsed < goal.currentAmount) {
                    return 'Сумма не может быть меньше уже накопленных средств (${currencyFormat.format(goal.currentAmount)})';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final updatedGoal = goal.copyWith(
                name: nameController.text.trim(),
                targetAmount: int.parse(amountController.text),
              );
              vm.updateGoal(updatedGoal).then((_) => Navigator.of(context).pop());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Находим цель в общем списке, чтобы отображать актуальную информацию
    final vm = context.watch<SavingsViewModel>();
    Goal? goal;
    try {
      goal = vm.goals.firstWhere((g) => g.id == widget.goalId);
    } catch (_) {
      goal = null;
    }
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Цель не найдена')),
        body: const Center(child: Text('Цель была удалена или недоступна.')),
      );
    }
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Статистика',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(goalId: goal.id!),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать цель',
            onPressed: () => _showEditGoalDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить цель?'),
                  content: const Text('Это действие нельзя отменить. Все транзакции для этой цели также будут удалены.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        vm.deleteGoal(widget.goalId).then((_) {
                          Navigator.of(context).pop(); // Закрыть диалог
                          Navigator.of(context).pop(); // Вернуться на HomeScreen
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Удалить цель',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Накоплено', style: Theme.of(context).textTheme.titleMedium),
                Text(currencyFormat.format(goal.currentAmount), style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Прогресс: ${(progress * 100).toStringAsFixed(1)}%'),
                  Text('Цель: ${currencyFormat.format(goal.targetAmount)}'),
                ]),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<model.Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Операций пока нет'));
                }
                final transactions = snapshot.data!;
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isDeposit = tx.amount > 0;
                    return ListTile(
                      leading: Icon(
                        isDeposit ? Icons.add_circle : Icons.remove_circle,
                        color: isDeposit ? Colors.green : Colors.red,
                      ),
                      title: Text(currencyFormat.format(tx.amount.abs())),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tx.notes != null && tx.notes!.isNotEmpty) Text(tx.notes!),
                          Text(DateFormat('dd.MM.yyyy HH:mm').format(tx.createdAt)),
                        ],
                      ),
                      isThreeLine: tx.notes != null && tx.notes!.isNotEmpty,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTransactionDialog(context, isWithdrawal: true),
                icon: const Icon(Icons.remove),
                label: const Text('Снять'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTransactionDialog(context, isWithdrawal: false),
                icon: const Icon(Icons.add),
                label: const Text('Пополнить'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/transaction.dart' as model;
import 'package:my_kopilka/features/savings/ui/screens/statistics_screen.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(goal.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Статистика',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(goalId: widget.goalId),
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF111827)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5F7FF), Color(0xFFFFFFFF)],
                ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: progress >= 1
                        ? const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF0EA5E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isDark
                            ? const LinearGradient(
                                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Накоплено',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(goal.currentAmount),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1 ? Colors.white : DarkColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Прогресс: ${(progress * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            'Цель: ${currencyFormat.format(goal.targetAmount)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<model.Transaction>>(
                    future: _transactionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: (isDark ? DarkColors.surface : Colors.white).withOpacity(isDark ? 0.9 : 0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: isDark ? DarkColors.primary : const Color(0xFF6366F1),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Операций пока нет',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Пополняйте или снимайте средства, чтобы видеть историю движений.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final transactions = snapshot.data!;
                      return Container(
                        decoration: BoxDecoration(
                          color: (isDark ? DarkColors.surface : Colors.white).withOpacity(isDark ? 0.9 : 0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isDeposit = tx.amount > 0;
                            final baseColor = isDeposit
                                ? (isDark ? DarkColors.income : LightColors.success)
                                : (isDark ? DarkColors.expense : LightColors.error);
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(isDark ? 0.16 : 0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: baseColor.withOpacity(isDark ? 0.3 : 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: baseColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currencyFormat.format(tx.amount.abs()),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : null,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy, HH:mm', 'ru').format(tx.createdAt),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isDark ? Colors.white70 : Colors.black54,
                                              ),
                                        ),
                                        if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            tx.notes!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: isDark ? Colors.white : null,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showAddTransactionDialog(context, isWithdrawal: true),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? DarkColors.surface : Colors.white,
                  foregroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
                label: const Text('Снять'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showAddTransactionDialog(context, isWithdrawal: false),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? DarkColors.primary : LightColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.arrow_downward_rounded),
                label: const Text('Пополнить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

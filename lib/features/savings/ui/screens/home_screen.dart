// lib/features/savings/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/ui/screens/goal_details_screen.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddGoalDialog(BuildContext context, SavingsViewModel vm) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая цель'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название цели'),
                validator: (value) => value!.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Сколько нужно?', hintText: 'Например: 5000'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Введите сумму';
                  if (int.tryParse(value) == null) return 'Неверный формат';
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
              if (formKey.currentState!.validate()) {
                final name = nameController.text;
                final amount = int.parse(amountController.text);
                vm.addGoal(name, amount);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Копилки'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.goals.isEmpty
              ? Center(
                  child: Text(
                    'У вас пока нет целей.\nНажмите "+", чтобы добавить первую!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: vm.goals.length,
                  itemBuilder: (context, index) {
                    final goal = vm.goals[index];
                    return GoalCard(goal: goal);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, vm),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GoalDetailsScreen(goalId: goal.id!),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currencyFormat.format(goal.currentAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(currencyFormat.format(goal.targetAmount)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${(progress * 100).toStringAsFixed(1)}%'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/ui/screens/goal_details_screen.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/features/settings/viewmodels/settings_view_model.dart';
import 'package:my_kopilka/features/savings/ui/screens/settings_screen.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.fetchGoals,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppGradients.cardDark : AppGradients.primary,
                ),
                child: const FlexibleSpaceBar(
                  title: Text(
                    'Мои Копилки',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Настройки',
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: vm.isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : vm.goals.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : SliverList(
                          delegate: SliverChildListDelegate([
                            _buildOverallStatsCard(context, vm, isDark),
                            const SizedBox(height: 16),

                            _buildSectionHeader(context, 'Мои цели', vm.goals.length),
                            const SizedBox(height: 8),

                            ...vm.goals.map((goal) => GoalCard(goal: goal)).toList(),

                            const SizedBox(height: 80),
                          ]),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, vm),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDark ? AppGradients.cardDark : AppGradients.primary,
              ),
              child: const Icon(
                Icons.savings,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Создайте свою первую копилку!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Поставьте цель и начните копить.\nКаждый рубль приближает к мечте!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard(BuildContext context, SavingsViewModel vm, bool isDark) {
    final totalSaved = vm.getTotalSaved();
    final totalGoals = vm.getTotalGoals();
    final progress = vm.getOverallProgress();
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.cardDark : AppGradients.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общий прогресс',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.primary : LightColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            currencyFormat.format(totalSaved),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'из ${currencyFormat.format(totalGoals)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? DarkColors.primary : LightColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Активных целей',
                  vm.getActiveGoals().length.toString(),
                  Icons.track_changes,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Достигнуто',
                  vm.getCompletedGoals().length.toString(),
                  Icons.check_circle,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? DarkColors.surface : LightColors.background).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isDark ? DarkColors.primary : LightColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context, SavingsViewModel vm) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddGoalDialog(context, vm),
      icon: const Icon(Icons.add),
      label: const Text('Новая цель'),
    );
  }

  void _showAddGoalDialog(BuildContext context, SavingsViewModel vm) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          bool isSubmitting = false;

          Future<void> submit() async {
            if (isSubmitting) return;
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => isSubmitting = true);
            try {
              final name = nameController.text.trim();
              final amount = int.parse(amountController.text);

              await vm.addGoal(name, amount);

              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Цель создана')),
              );
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось создать цель')),
              );
            } finally {
              if (context.mounted) setDialogState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Новая цель накопления'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название цели',
                      hintText: 'Например: Отпуск в Турции',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Сумма цели',
                      hintText: 'Например: 50000',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: '₽',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Введите сумму';
                      final parsed = int.tryParse(value!);
                      if (parsed == null) return 'Неверный формат';
                      if (parsed <= 0) return 'Сумма должна быть больше нуля';
                      return null;
                    },
                    onFieldSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать'),
              ),
            ],
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.read<SavingsViewModel>();
    final settingsVM = context.read<SettingsViewModel>();
    final motivationalMessage = vm.getMotivationalMessage(goal);
    final isCompleted = goal.currentAmount >= goal.targetAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GoalDetailsScreen(goalId: goal.id!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                if (motivationalMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      motivationalMessage,
                      style: TextStyle(
                        color: isDark ? DarkColors.primary : LightColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Накоплено', style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          currencyFormat.format(goal.currentAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Цель', style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          currencyFormat.format(goal.targetAmount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (!isCompleted)
                          Text(
                            'Осталось: ${currencyFormat.format(goal.targetAmount - goal.currentAmount)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            backgroundColor: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? (isDark ? DarkColors.success : LightColors.success)
                                  : (isDark ? DarkColors.primary : LightColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!isCompleted)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: settingsVM.settings.quickAddPresets.map((amount) {
                      return SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await vm.addTransaction(goal.id!, amount);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Добавлено +$amount ₽')),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Не удалось добавить сумму')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: BorderSide(
                              color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            '+$amount ₽',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

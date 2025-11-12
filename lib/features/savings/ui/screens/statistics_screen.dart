// lib/features/savings/ui/screens/statistics_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/statistics.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/features/settings/viewmodels/settings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  final int goalId;

  const StatisticsScreen({super.key, required this.goalId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Future<SavingsStatistics>? _statisticsFuture;
  int? _lastKnownAmount;
  int? _lastKnownTarget;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final vm = context.read<SavingsViewModel>();
    final goal = _resolveGoal(vm.goals, widget.goalId);
    if (goal != null) {
      _statisticsFuture = vm.getStatisticsForGoal(goal.id!);
      _lastKnownAmount = goal.currentAmount;
      _lastKnownTarget = goal.targetAmount;
    }
    _bootstrapped = true;
  }

  Goal? _resolveGoal(List<Goal> goals, int id) {
    for (final goal in goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  Future<void> _handleRefresh() async {
    final vm = context.read<SavingsViewModel>();
    final goal = _resolveGoal(vm.goals, widget.goalId);
    if (goal == null) return;

    final future = vm.getStatisticsForGoal(goal.id!);
    setState(() {
      _statisticsFuture = future;
      _lastKnownAmount = goal.currentAmount;
      _lastKnownTarget = goal.targetAmount;
    });
    await future;
  }

  void _scheduleStatisticsReload(Goal goal) {
    if (!mounted) return;

    final vm = context.read<SavingsViewModel>();
    final future = vm.getStatisticsForGoal(goal.id!);
    setState(() {
      _statisticsFuture = future;
      _lastKnownAmount = goal.currentAmount;
      _lastKnownTarget = goal.targetAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<SavingsViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final goal = _resolveGoal(vm.goals, widget.goalId);

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
        ),
        body: const Center(
          child: Text('Цель не найдена.'),
        ),
      );
    }

    if ((_lastKnownAmount != goal.currentAmount || _lastKnownTarget != goal.targetAmount) &&
        WidgetsBinding.instance != null) {
      _lastKnownAmount = goal.currentAmount;
      _lastKnownTarget = goal.targetAmount;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleStatisticsReload(goal));
    }

    final predictions =
        settings.settings.showPredictions ? vm.getPredictions(goal) : <PredictionModel>[];
    final motivation = vm.getMotivationalMessage(goal);
    final statsFuture = _statisticsFuture;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Статистика: ${goal.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => _handleRefresh(),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: isDark ? DarkColors.primary : LightColors.primary,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(context, goal, motivation, isDark),
                  const SizedBox(height: 20),

                  if (settings.settings.showPredictions && predictions.isNotEmpty) ...[
                    _buildPredictionsCard(context, predictions, isDark),
                    const SizedBox(height: 20),
                  ],

                  if (statsFuture == null)
                    const _LoadingCard()
                  else
                    FutureBuilder<SavingsStatistics>(
                      future: statsFuture,
                      builder: (context, snapshot) {
                        Widget child;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          child = const _LoadingCard();
                        } else if (snapshot.hasError) {
                          child = _ErrorCard(
                            onRetry: _handleRefresh,
                            message: 'Не удалось загрузить статистику',
                          );
                        } else if (snapshot.hasData) {
                          child = Column(
                            key: const ValueKey('stats-loaded'),
                            children: [
                              _buildStatsCard(context, snapshot.data!, isDark),
                              const SizedBox(height: 20),
                              _buildTransactionBreakdown(context, snapshot.data!, isDark),
                            ],
                          );
                        } else {
                          child = const _EmptyCard();
                        }

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: child,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    Goal goal,
    String motivation,
    bool isDark,
  ) {
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.cardDark : AppGradients.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогресс цели',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? DarkColors.textPrimary : Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark ? DarkColors.textPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            currencyFormat.format(goal.currentAmount),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isDark ? DarkColors.textPrimary : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            'из ${currencyFormat.format(goal.targetAmount)}',
            style: TextStyle(
              color: (isDark ? DarkColors.textPrimary : Colors.white).withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 20),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? DarkColors.secondary : Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (remaining > 0)
            Text(
              'Осталось: ${currencyFormat.format(remaining)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: (isDark ? DarkColors.textPrimary : Colors.white).withOpacity(0.9),
                  ),
            ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.18 : 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motivation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? DarkColors.textPrimary : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(BuildContext context, List<PredictionModel> predictions, bool isDark) {
    return _FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights,
                  color: isDark ? DarkColors.primary : LightColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Прогноз достижения цели',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (predictions.isEmpty)
            const Text('Цель уже достигнута! 🎉')
          else
            ...predictions.map((prediction) => _buildPredictionRow(
                  context,
                  prediction,
                  isDark,
                )),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(BuildContext context, PredictionModel prediction, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ru');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? DarkColors.surface : Colors.white).withOpacity(isDark ? 0.65 : 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'По ${prediction.dailyAmount} ₽ в день',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${prediction.daysToGoal} дней',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: isDark ? DarkColors.primary : LightColors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                dateFormat.format(prediction.estimatedDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, SavingsStatistics stats, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    return _FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика операций',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Пополнения',
                  currencyFormat.format(stats.totalDeposits),
                  Icons.add_circle,
                  isDark ? DarkColors.income : LightColors.success,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Снятия',
                  currencyFormat.format(stats.totalWithdrawals),
                  Icons.remove_circle,
                  isDark ? DarkColors.expense : LightColors.error,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Среднее пополнение',
                  currencyFormat.format(stats.averageDeposit),
                  Icons.trending_up,
                  isDark ? DarkColors.primary : LightColors.primary,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Операций всего',
                  stats.totalTransactions.toString(),
                  Icons.receipt_long,
                  isDark ? DarkColors.secondary : LightColors.secondary,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown(BuildContext context, SavingsStatistics stats, bool isDark) {
    if (stats.totalTransactions == 0) return const SizedBox();

    final totalFlow = stats.totalDeposits + stats.totalWithdrawals;
    if (totalFlow == 0) {
      return const SizedBox();
    }

    final depositPercent = stats.totalDeposits / totalFlow;
    final withdrawalPercent = 1 - depositPercent;

    return _FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Соотношение операций',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  isDark ? DarkColors.income : LightColors.success,
                  isDark ? DarkColors.expense : LightColors.error,
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (depositPercent * 100).round().clamp(0, 100),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  flex: (withdrawalPercent * 100).round().clamp(0, 100),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                color: isDark ? DarkColors.income : LightColors.success,
                label: 'Пополнения ${(depositPercent * 100).toStringAsFixed(1)}%',
              ),
              _LegendItem(
                color: isDark ? DarkColors.expense : LightColors.error,
                label: 'Снятия ${(withdrawalPercent * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('stats-loading'),
      children: const [
        _ShimmerPlaceholder(height: 180),
        SizedBox(height: 20),
        _ShimmerPlaceholder(height: 160),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      key: const ValueKey('stats-empty'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Нет данных для отображения',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте несколько операций, чтобы увидеть аналитику по цели.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FrostedCard extends StatelessWidget {
  final Widget child;
  const _FrostedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white12 : Colors.white.withOpacity(0.92)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.09),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final double height;
  const _ShimmerPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            (isDark ? DarkColors.surface : LightColors.background).withOpacity(0.7),
            (isDark ? DarkColors.surface : LightColors.background).withOpacity(0.3),
            (isDark ? DarkColors.surface : LightColors.background).withOpacity(0.7),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String message;

  const _ErrorCard({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      key: const ValueKey('stats-error'),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

// lib/features/savings/ui/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/models/statistics.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  final Goal goal;
  
  const StatisticsScreen({super.key, required this.goal});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<SavingsStatistics> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    final vm = Provider.of<SavingsViewModel>(context, listen: false);
    setState(() {
      _statisticsFuture = vm.getStatisticsForGoal(widget.goal.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<SavingsViewModel>();
    final predictions = vm.getPredictions(widget.goal);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистика: ${widget.goal.name}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка с основной информацией
            _buildProgressCard(context, widget.goal, isDark),
            const SizedBox(height: 16),
            
            // Предсказания
            _buildPredictionsCard(context, predictions, isDark),
            const SizedBox(height: 16),
            
            // Статистика транзакций
            FutureBuilder<SavingsStatistics>(
              future: _statisticsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: Text('Нет данных'));
                }
                
                final stats = snapshot.data!;
                return Column(
                  children: [
                    _buildStatsCard(context, stats, isDark),
                    const SizedBox(height: 16),
                    _buildTransactionBreakdown(context, stats, isDark),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Goal goal, bool isDark) {
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.cardDark : AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.3),
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
                'Прогресс цели',
                style: TextStyle(
                  color: isDark ? DarkColors.textPrimary : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                  style: TextStyle(
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
            style: TextStyle(
              color: isDark ? DarkColors.textPrimary : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
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
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? DarkColors.secondary : Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (remaining > 0)
            Text(
              'Осталось: ${currencyFormat.format(remaining)}',
              style: TextStyle(
                color: (isDark ? DarkColors.textPrimary : Colors.white).withOpacity(0.9),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(BuildContext context, List<PredictionModel> predictions, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: isDark ? DarkColors.primary : LightColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Прогноз достижения цели',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (predictions.isEmpty)
              const Text('Цель уже достигнута! 🎉')
            else
              ...predictions.map((prediction) => _buildPredictionRow(
                context,
                prediction,
                isDark,
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionRow(BuildContext context, PredictionModel prediction, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ru');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? DarkColors.surface : LightColors.background).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.5),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
                size: 16,
                color: isDark ? DarkColors.primary : LightColors.primary,
              ),
              Text(
                dateFormat.format(prediction.estimatedDate),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, SavingsStatistics stats, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика операций',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
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
                    Icons.receipt,
                    isDark ? DarkColors.secondary : LightColors.secondary,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown(BuildContext context, SavingsStatistics stats, bool isDark) {
    if (stats.totalTransactions == 0) return const SizedBox();
    
    final depositPercent = stats.totalDeposits / (stats.totalDeposits + stats.totalWithdrawals);
    final withdrawalPercent = 1 - depositPercent;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Соотношение операций',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Визуальная полоса соотношения
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (depositPercent * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.income : LightColors.success,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (withdrawalPercent * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.expense : LightColors.error,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.income : LightColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Пополнения ${(depositPercent * 100).toStringAsFixed(1)}%'),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.expense : LightColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Снятия ${(withdrawalPercent * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

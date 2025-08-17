// lib/features/savings/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_kopilka/features/savings/models/goal.dart';
import 'package:my_kopilka/features/savings/ui/screens/goal_details_screen.dart';
import 'package:my_kopilka/features/savings/ui/screens/statistics_screen.dart';
import 'package:my_kopilka/features/achievements/ui/screens/achievements_screen.dart';
import 'package:my_kopilka/features/settings/ui/screens/settings_screen.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/features/settings/viewmodels/settings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Красивый AppBar с градиентом
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppGradients.cardDark : AppGradients.primary,
              ),
              child: FlexibleSpaceBar(
                title: const Text(
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
                icon: const Icon(Icons.emoji_events, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),

          // Контент
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
                          // Общая статистика
                          _buildOverallStatsCard(context, vm, isDark),
                          const SizedBox(height: 16),
                          
                          // Последние достижения
                          if (vm.unlockedAchievements.isNotEmpty)
                            _buildRecentAchievements(context, vm, isDark),
                          
                          // Заголовок целей
                          _buildSectionHeader(context, 'Мои цели', vm.goals.length),
                          const SizedBox(height: 8),
                          
                          // Список целей
                          ...vm.goals.map((goal) => GoalCard(goal: goal)).toList(),
                          
                          const SizedBox(height: 80), // Отступ для FAB
                        ]),
                      ),
          ),
        ],
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

  Widget _buildRecentAchievements(BuildContext context, SavingsViewModel vm, bool isDark) {
    final recentAchievements = vm.unlockedAchievements.take(3).toList();
    
    return Column(
      children: [
        _buildSectionHeader(context, '🏆 Последние достижения', recentAchievements.length),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentAchievements.length,
            itemBuilder: (context, index) {
              final achievement = recentAchievements[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.2),
                        border: Border.all(
                          color: isDark ? DarkColors.primary : LightColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
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

  void _showAddGoalDialog(BuildContext context, SavingsViewModel vm

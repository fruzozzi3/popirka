// lib/features/achievements/ui/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:my_kopilka/features/savings/models/achievement.dart';
import 'package:my_kopilka/features/savings/viewmodels/savings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final unlockedAchievements = vm.achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = vm.achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика достижений
            _buildStatsCard(context, unlockedAchievements.length, vm.achievements.length, isDark),
            const SizedBox(height: 24),
            
            // Открытые достижения
            if (unlockedAchievements.isNotEmpty) ...[
              _buildSectionTitle(context, '🏆 Полученные награды', unlockedAchievements.length),
              const SizedBox(height: 16),
              ...unlockedAchievements.map((achievement) => 
                _buildAchievementCard(context, achievement, isDark, true),
              ),
              const SizedBox(height: 24),
            ],
            
            // Заблокированные достижения
            if (lockedAchievements.isNotEmpty) ...[
              _buildSectionTitle(context, '🎯 К получению', lockedAchievements.length),
              const SizedBox(height: 16),
              ...lockedAchievements.map((achievement) => 
                _buildAchievementCard(context, achievement, isDark, false),
              ),
            ],
            
            if (vm.achievements.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      '🎮',
                      style: TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Достижения загружаются...',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, int unlocked, int total, bool isDark) {
    final progress = total > 0 ? unlocked / total : 0.0;
    
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Прогресс достижений',
                    style: TextStyle(
                      color: isDark ? DarkColors.textPrimary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlocked из $total',
                    style: TextStyle(
                      color: isDark ? DarkColors.textPrimary : Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: isDark ? DarkColors.textPrimary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildAchievementCard(BuildContext context, Achievement achievement, bool isDark, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Иконка достижения
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.2)
                      : (isDark ? DarkColors.border : LightColors.border).withOpacity(0.3),
                  border: Border.all(
                    color: isUnlocked
                        ? (isDark ? DarkColors.primary : LightColors.primary)
                        : (isDark ? DarkColors.border : LightColors.border),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 28,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Информация о достижении
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? null : Colors.grey,
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Icon(
                            Icons.check_circle,
                            color: isDark ? DarkColors.success : LightColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUnlocked 
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Colors.grey,
                      ),
                    ),
                    
                    if (!isUnlocked && achievement.maxProgress > 1) ...[
                      const SizedBox(height: 8),
                      
                      // Прогресс бар для достижений с прогрессом
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Прогресс',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${achievement.progress}/${achievement.maxProgress}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievement.progressPercent,
                              minHeight: 6,
                              backgroundColor: (isDark ? DarkColors.border : LightColors.border).withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? DarkColors.primary : LightColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (isUnlocked && achievement.unlockedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Получено ${DateFormat('dd.MM.yyyy').format(achievement.unlockedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? DarkColors.success : LightColors.success,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

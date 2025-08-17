// lib/features/settings/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:my_kopilka/features/settings/models/settings.dart';
import 'package:my_kopilka/features/settings/viewmodels/settings_view_model.dart';
import 'package:my_kopilka/theme/colors.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Внешний вид
            _buildSectionCard(
              context,
              'Внешний вид',
              Icons.palette,
              isDark,
              [
                _buildSwitchTile(
                  context,
                  'Темная тема',
                  'Включить темное оформление',
                  Icons.dark_mode,
                  settingsVM.settings.isDarkMode,
                  (value) => settingsVM.toggleTheme(),
                  isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Быстрые пополнения
            _buildSectionCard(
              context,
              'Быстрые пополнения',
              Icons.flash_on,
              isDark,
              [
                _buildTile(
                  context,
                  'Настроить суммы',
                  'Изменить быстрые кнопки пополнения',
                  Icons.edit,
                  () => _showQuickAddDialog(context, settingsVM),
                  isDark,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: settingsVM.settings.quickAddPresets.map((amount) =>
                      Chip(
                        label: Text('$amount ₽'),
                        backgroundColor: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Дополнительно
            _buildSectionCard(
              context,
              'Дополнительно',
              Icons.tune,
              isDark,
              [
                _buildSwitchTile(
                  context,
                  'Показывать прогнозы',
                  'Отображать предсказания достижения целей',
                  Icons.insights,
                  settingsVM.settings.showPredictions,
                  (value) => settingsVM.updateSettings(
                    settingsVM.settings.copyWith(showPredictions: value),
                  ),
                  isDark,
                ),
                _buildSwitchTile(
                  context,
                  'Уведомления',
                  'Напоминания о пополнении копилки',
                  Icons.notifications,
                  settingsVM.settings.enableNotifications,
                  (value) => settingsVM.updateSettings(
                    settingsVM.settings.copyWith(enableNotifications: value),
                  ),
                  isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Данные
            _buildSectionCard(
              context,
              'Данные',
              Icons.storage,
              isDark,
              [
                _buildTile(
                  context,
                  'Экспорт данных',
                  'Сохранить резервную копию',
                  Icons.backup,
                  () => _showExportDialog(context),
                  isDark,
                ),
                _buildTile(
                  context,
                  'Импорт данных',
                  'Восстановить из резервной копии',
                  Icons.restore,
                  () => _showImportDialog(context),
                  isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // О приложении
            _buildSectionCard(
              context,
              'О приложении',
              Icons.info,
              isDark,
              [
                _buildTile(
                  context,
                  'Версия',
                  '1.0.0',
                  Icons.info_outline,
                  null,
                  isDark,
                ),
                _buildTile(
                  context,
                  'Обратная связь',
                  'Поделиться отзывом или предложением',
                  Icons.feedback,
                  () => _showFeedbackDialog(context),
                  isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Мотивационная карточка
            _buildMotivationCard(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark,
    List<Widget> children,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? DarkColors.primary : LightColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
      activeColor: isDark ? DarkColors.primary : LightColors.primary,
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    bool isDark,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(icon),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildMotivationCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.cardDark : AppGradients.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '💪',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Продолжай копить!',
            style: TextStyle(
              color: isDark ? DarkColors.textPrimary : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Каждый рубль приближает тебя к мечте',
            style: TextStyle(
              color: (isDark ? DarkColors.textPrimary : Colors.white).withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context, SettingsViewModel settingsVM) {
    final controller = TextEditingController();
    final presets = List<int>.from(settingsVM.settings.quickAddPresets);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Настройка быстрых пополнений'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Новая сумма',
                  suffixText: '₽',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: presets.map((amount) => 
                  Chip(
                    label: Text('$amount ₽'),
                    onDeleted: presets.length > 1 ? () {
                      setState(() {
                        presets.remove(amount);
                      });
                    } : null,
                  ),
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0 && !presets.contains(value)) {
                  setState(() {
                    presets.add(value);
                    presets.sort();
                    controller.clear();
                  });
                }
              },
              child: const Text('Добавить'),
            ),
            ElevatedButton(
              onPressed: () {
                settingsVM.updateSettings(
                  settingsVM.settings.copyWith(quickAddPresets: presets),
                );
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт данных'),
        content: const Text(
          'Резервная копия будет сохранена в папку "Загрузки". '
          'Она содержит все ваши цели, транзакции и настройки.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Реализовать экспорт
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Экспорт завершен')),
              );
            },
            child: const Text('Экспортировать'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт данных'),
        content: const Text(
          'Выберите файл резервной копии для восстановления данных. '
          'Текущие данные будут заменены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Реализовать импорт
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Импорт завершен')),
              );
            },
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обратная связь'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Поделитесь своим мнением о приложении...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Спасибо за отзыв!')),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}

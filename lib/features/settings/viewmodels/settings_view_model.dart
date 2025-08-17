// lib/features/settings/viewmodels/settings_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings.dart';

class SettingsViewModel extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  static const String _settingsKey = 'app_settings';

  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromMap(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = const AppSettings();
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toMap());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleTheme() async {
    final newSettings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> updateCurrency(String currency) async {
    final newSettings = _settings.copyWith(currency: currency);
    await updateSettings(newSettings);
  }

  Future<void> updateQuickAddPresets(List<int> presets) async {
    final newSettings = _settings.copyWith(quickAddPresets: presets);
    await updateSettings(newSettings);
  }

  Future<void> resetToDefault() async {
    _settings = const AppSettings();
    notifyListeners();
    await _saveSettings();
  }
}

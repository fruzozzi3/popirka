// lib/features/settings/models/settings.dart
class AppSettings {
  final bool isDarkMode;
  final String currency;
  final String language;
  final List<int> quickAddPresets;
  final bool showPredictions;
  final bool enableNotifications;

  const AppSettings({
    this.isDarkMode = false,
    this.currency = '₽',
    this.language = 'ru',
    this.quickAddPresets = const [50, 100, 200, 500, 1000],
    this.showPredictions = true,
    this.enableNotifications = true,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? currency,
    String? language,
    List<int>? quickAddPresets,
    bool? showPredictions,
    bool? enableNotifications,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      quickAddPresets: quickAddPresets ?? this.quickAddPresets,
      showPredictions: showPredictions ?? this.showPredictions,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'currency': currency,
      'language': language,
      'quickAddPresets': quickAddPresets,
      'showPredictions': showPredictions,
      'enableNotifications': enableNotifications,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      currency: map['currency'] ?? '₽',
      language: map['language'] ?? 'ru',
      quickAddPresets: List<int>.from(map['quickAddPresets'] ?? [50, 100, 200, 500, 1000]),
      showPredictions: map['showPredictions'] ?? true,
      enableNotifications: map['enableNotifications'] ?? true,
    );
  }
}

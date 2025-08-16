import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/database/hive_database.dart';

part 'settings_provider.g.dart';

/// Provider pour les paramètres de l'application
@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    final settingsBox = HiveDatabase.settingsBox;
    
    return AppSettings(
      themeMode: _getThemeMode(settingsBox.get('theme_mode', defaultValue: 'system')),
      firstDayOfWeek: settingsBox.get('first_day_of_week', defaultValue: 1),
      snapInterval: settingsBox.get('snap_interval', defaultValue: 15),
      defaultTaskDuration: settingsBox.get('default_task_duration', defaultValue: 60),
      notificationsEnabled: settingsBox.get('notifications_enabled', defaultValue: true),
      soundEnabled: settingsBox.get('sound_enabled', defaultValue: true),
      vibrationEnabled: settingsBox.get('vibration_enabled', defaultValue: true),
      onboardingCompleted: settingsBox.get('onboarding_completed', defaultValue: false),
      firstLaunch: settingsBox.get('first_launch', defaultValue: true),
      appVersion: settingsBox.get('app_version', defaultValue: '1.0.0'),
    );
  }

  /// Met à jour le mode de thème
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('theme_mode', _themeModeToString(themeMode));
    state = state.copyWith(themeMode: themeMode);
  }

  /// Met à jour le premier jour de la semaine
  Future<void> setFirstDayOfWeek(int firstDay) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('first_day_of_week', firstDay);
    state = state.copyWith(firstDayOfWeek: firstDay);
  }

  /// Met à jour l'intervalle de snap
  Future<void> setSnapInterval(int interval) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('snap_interval', interval);
    state = state.copyWith(snapInterval: interval);
  }

  /// Met à jour la durée par défaut des tâches
  Future<void> setDefaultTaskDuration(int duration) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('default_task_duration', duration);
    state = state.copyWith(defaultTaskDuration: duration);
  }

  /// Active/désactive les notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('notifications_enabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Active/désactive le son
  Future<void> setSoundEnabled(bool enabled) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('sound_enabled', enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  /// Active/désactive les vibrations
  Future<void> setVibrationEnabled(bool enabled) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('vibration_enabled', enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  /// Marque l'onboarding comme terminé
  Future<void> completeOnboarding() async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('onboarding_completed', true);
    await settingsBox.put('first_launch', false);
    state = state.copyWith(
      onboardingCompleted: true,
      firstLaunch: false,
    );
  }

  /// Met à jour la version de l'app
  Future<void> setAppVersion(String version) async {
    final settingsBox = HiveDatabase.settingsBox;
    await settingsBox.put('app_version', version);
    state = state.copyWith(appVersion: version);
  }

  /// Réinitialise tous les paramètres
  Future<void> resetToDefaults() async {
    final settingsBox = HiveDatabase.settingsBox;
    
    await settingsBox.put('theme_mode', 'system');
    await settingsBox.put('first_day_of_week', 1);
    await settingsBox.put('snap_interval', 15);
    await settingsBox.put('default_task_duration', 60);
    await settingsBox.put('notifications_enabled', true);
    await settingsBox.put('sound_enabled', true);
    await settingsBox.put('vibration_enabled', true);
    
    state = AppSettings.defaults();
  }

  /// Convertit une string en ThemeMode
  ThemeMode _getThemeMode(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convertit un ThemeMode en string
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Provider pour le mode de thème actuel
@riverpod
ThemeMode currentThemeMode(CurrentThemeModeRef ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode;
}

/// Provider pour vérifier si c'est le premier lancement
@riverpod
bool isFirstLaunch(IsFirstLaunchRef ref) {
  final settings = ref.watch(settingsProvider);
  return settings.firstLaunch;
}

/// Provider pour vérifier si l'onboarding est terminé
@riverpod
bool isOnboardingCompleted(IsOnboardingCompletedRef ref) {
  final settings = ref.watch(settingsProvider);
  return settings.onboardingCompleted;
}

/// Provider pour les paramètres de notifications
@riverpod
NotificationSettings notificationSettings(NotificationSettingsRef ref) {
  final settings = ref.watch(settingsProvider);
  return NotificationSettings(
    enabled: settings.notificationsEnabled,
    soundEnabled: settings.soundEnabled,
    vibrationEnabled: settings.vibrationEnabled,
  );
}

/// Provider pour les paramètres de l'interface utilisateur
@riverpod
UISettings uiSettings(UISettingsRef ref) {
  final settings = ref.watch(settingsProvider);
  return UISettings(
    firstDayOfWeek: settings.firstDayOfWeek,
    snapInterval: settings.snapInterval,
    defaultTaskDuration: settings.defaultTaskDuration,
  );
}

/// Provider pour l'export des paramètres
@riverpod
Map<String, dynamic> exportSettings(ExportSettingsRef ref) {
  final settingsBox = HiveDatabase.settingsBox;
  return Map<String, dynamic>.from(settingsBox.toMap());
}

/// Provider pour l'import des paramètres
@riverpod
class SettingsImporter extends _$SettingsImporter {
  @override
  ImportState build() {
    return const ImportState();
  }

  /// Importe des paramètres depuis un Map
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    state = const ImportState(isImporting: true);
    
    try {
      final settingsBox = HiveDatabase.settingsBox;
      
      for (final entry in settingsData.entries) {
        await settingsBox.put(entry.key, entry.value);
      }
      
      // Rafraîchir les paramètres
      ref.invalidate(settingsProvider);
      
      state = const ImportState(isImporting: false, success: true);
    } catch (e) {
      state = ImportState(
        isImporting: false,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Efface l'état d'import
  void clearImportState() {
    state = const ImportState();
  }
}

/// Classe pour les paramètres de l'application
class AppSettings {
  final ThemeMode themeMode;
  final int firstDayOfWeek; // 1 = Lundi, 7 = Dimanche
  final int snapInterval; // 5 ou 15 minutes
  final int defaultTaskDuration; // en minutes
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool onboardingCompleted;
  final bool firstLaunch;
  final String appVersion;

  const AppSettings({
    required this.themeMode,
    required this.firstDayOfWeek,
    required this.snapInterval,
    required this.defaultTaskDuration,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.onboardingCompleted,
    required this.firstLaunch,
    required this.appVersion,
  });

  /// Paramètres par défaut
  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.system,
      firstDayOfWeek: 1, // Lundi
      snapInterval: 15, // 15 minutes
      defaultTaskDuration: 60, // 1 heure
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      onboardingCompleted: false,
      firstLaunch: true,
      appVersion: '1.0.0',
    );
  }

  /// Copie avec de nouveaux paramètres
  AppSettings copyWith({
    ThemeMode? themeMode,
    int? firstDayOfWeek,
    int? snapInterval,
    int? defaultTaskDuration,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? onboardingCompleted,
    bool? firstLaunch,
    String? appVersion,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      snapInterval: snapInterval ?? this.snapInterval,
      defaultTaskDuration: defaultTaskDuration ?? this.defaultTaskDuration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  /// Obtient le libellé du premier jour de la semaine
  String get firstDayOfWeekLabel {
    switch (firstDayOfWeek) {
      case 1:
        return 'Lundi';
      case 7:
        return 'Dimanche';
      default:
        return 'Lundi';
    }
  }

  /// Obtient le libellé de l'intervalle de snap
  String get snapIntervalLabel {
    return '$snapInterval minutes';
  }

  /// Obtient le libellé de la durée par défaut
  String get defaultTaskDurationLabel {
    if (defaultTaskDuration < 60) {
      return '$defaultTaskDuration minutes';
    } else {
      final hours = defaultTaskDuration ~/ 60;
      final minutes = defaultTaskDuration % 60;
      if (minutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''}';
      } else {
        return '${hours}h${minutes}min';
      }
    }
  }

  /// Obtient le libellé du mode de thème
  String get themeModeLabel {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }
}

/// Classe pour les paramètres de notifications
class NotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    required this.enabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });
}

/// Classe pour les paramètres de l'interface utilisateur
class UISettings {
  final int firstDayOfWeek;
  final int snapInterval;
  final int defaultTaskDuration;

  const UISettings({
    required this.firstDayOfWeek,
    required this.snapInterval,
    required this.defaultTaskDuration,
  });
}

/// État d'import des paramètres
class ImportState {
  final bool isImporting;
  final bool success;
  final String? error;

  const ImportState({
    this.isImporting = false,
    this.success = false,
    this.error,
  });
}

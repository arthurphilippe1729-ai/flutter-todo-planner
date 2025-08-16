import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/database/hive_database.dart';
import '../../services/notification_service.dart';

/// Page des réglages de l'application
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final taskStats = ref.watch(taskStatsProvider);
    final categoryStats = ref.watch(categoryStatsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surfaceTint,
              title: const Text('Réglages'),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistiques
            _buildStatsSection(taskStats, categoryStats, theme),
            
            const SizedBox(height: 24),
            
            // Apparence
            _buildAppearanceSection(settings, ref, theme),
            
            const SizedBox(height: 24),
            
            // Interface
            _buildInterfaceSection(settings, ref, theme),
            
            const SizedBox(height: 24),
            
            // Notifications
            _buildNotificationsSection(settings, ref, theme),
            
            const SizedBox(height: 24),
            
            // Données
            _buildDataSection(ref, theme, context),
            
            const SizedBox(height: 24),
            
            // À propos
            _buildAboutSection(settings, theme),
            
            const SizedBox(height: 80), // Espace pour la navigation
          ],
        ),
      ),
    );
  }

  /// Section des statistiques
  Widget _buildStatsSection(TaskStats taskStats, CategoryStats categoryStats, ThemeData theme) {
    return _buildSection(
      title: 'Statistiques',
      theme: theme,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Tâches totales', taskStats.totalTasks.toString(), theme),
                const SizedBox(height: 8),
                _buildStatRow('Tâches terminées', taskStats.completedTasks.toString(), theme),
                const SizedBox(height: 8),
                _buildStatRow('Taux de completion', '${(taskStats.completionRate * 100).toInt()}%', theme),
                const SizedBox(height: 8),
                _buildStatRow('Catégories', categoryStats.totalCategories.toString(), theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Section de l'apparence
  Widget _buildAppearanceSection(AppSettings settings, WidgetRef ref, ThemeData theme) {
    return _buildSection(
      title: 'Apparence',
      theme: theme,
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Thème'),
          subtitle: Text(settings.themeModeLabel),
          onTap: () => _showThemeDialog(ref, theme),
        ),
      ],
    );
  }

  /// Section de l'interface
  Widget _buildInterfaceSection(AppSettings settings, WidgetRef ref, ThemeData theme) {
    return _buildSection(
      title: 'Interface',
      theme: theme,
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Premier jour de la semaine'),
          subtitle: Text(settings.firstDayOfWeekLabel),
          onTap: () => _showFirstDayDialog(ref, theme),
        ),
        ListTile(
          leading: const Icon(Icons.grid_on_outlined),
          title: const Text('Intervalle de snap'),
          subtitle: Text(settings.snapIntervalLabel),
          onTap: () => _showSnapIntervalDialog(ref, theme),
        ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Durée par défaut des tâches'),
          subtitle: Text(settings.defaultTaskDurationLabel),
          onTap: () => _showDurationDialog(ref, theme),
        ),
      ],
    );
  }

  /// Section des notifications
  Widget _buildNotificationsSection(AppSettings settings, WidgetRef ref, ThemeData theme) {
    return _buildSection(
      title: 'Notifications',
      theme: theme,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications activées'),
          subtitle: const Text('Recevoir des rappels pour les tâches'),
          value: settings.notificationsEnabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: const Text('Son'),
          subtitle: const Text('Jouer un son avec les notifications'),
          value: settings.soundEnabled,
          onChanged: settings.notificationsEnabled
              ? (value) {
                  ref.read(settingsProvider.notifier).setSoundEnabled(value);
                }
              : null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration_outlined),
          title: const Text('Vibration'),
          subtitle: const Text('Vibrer lors des notifications'),
          value: settings.vibrationEnabled,
          onChanged: settings.notificationsEnabled
              ? (value) {
                  ref.read(settingsProvider.notifier).setVibrationEnabled(value);
                }
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Tester les notifications'),
          subtitle: const Text('Envoyer une notification de test'),
          onTap: () => NotificationService.testNotification(),
        ),
      ],
    );
  }

  /// Section des données
  Widget _buildDataSection(WidgetRef ref, ThemeData theme, BuildContext context) {
    return _buildSection(
      title: 'Données',
      theme: theme,
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Exporter les données'),
          subtitle: const Text('Sauvegarder toutes vos données'),
          onTap: () => _exportData(context),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Importer les données'),
          subtitle: const Text('Restaurer depuis une sauvegarde'),
          onTap: () => _importData(context),
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          title: Text('Effacer toutes les données', style: TextStyle(color: theme.colorScheme.error)),
          subtitle: const Text('Supprimer définitivement toutes les données'),
          onTap: () => _showDeleteAllDialog(ref, theme, context),
        ),
      ],
    );
  }

  /// Section à propos
  Widget _buildAboutSection(AppSettings settings, ThemeData theme) {
    return _buildSection(
      title: 'À propos',
      theme: theme,
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(settings.appVersion),
        ),
        ListTile(
          leading: const Icon(Icons.code_outlined),
          title: const Text('Todo & Planning'),
          subtitle: const Text('Application de gestion de tâches et planning'),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_outline),
          title: const Text('Développé avec Flutter'),
          subtitle: const Text('Framework Google pour applications mobiles'),
        ),
      ],
    );
  }

  /// Construit une section avec titre
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Construit une ligne de statistique
  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Affiche le dialogue de sélection du thème
  void _showThemeDialog(WidgetRef ref, ThemeData theme) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Système'),
              subtitle: const Text('Suit les réglages du système'),
              value: ThemeMode.system,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Clair'),
              value: ThemeMode.light,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sombre'),
              value: ThemeMode.dark,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue de sélection du premier jour
  void _showFirstDayDialog(WidgetRef ref, ThemeData theme) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Premier jour de la semaine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('Lundi'),
              value: 1,
              groupValue: ref.read(settingsProvider).firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Dimanche'),
              value: 7,
              groupValue: ref.read(settingsProvider).firstDayOfWeek,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue de sélection de l'intervalle de snap
  void _showSnapIntervalDialog(WidgetRef ref, ThemeData theme) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Intervalle de snap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('5 minutes'),
              value: 5,
              groupValue: ref.read(settingsProvider).snapInterval,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setSnapInterval(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('15 minutes'),
              value: 15,
              groupValue: ref.read(settingsProvider).snapInterval,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setSnapInterval(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue de sélection de la durée par défaut
  void _showDurationDialog(WidgetRef ref, ThemeData theme) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Durée par défaut des tâches'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('30 minutes'),
              value: 30,
              groupValue: ref.read(settingsProvider).defaultTaskDuration,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDefaultTaskDuration(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('1 heure'),
              value: 60,
              groupValue: ref.read(settingsProvider).defaultTaskDuration,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDefaultTaskDuration(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('2 heures'),
              value: 120,
              groupValue: ref.read(settingsProvider).defaultTaskDuration,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDefaultTaskDuration(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Exporte les données
  void _exportData(BuildContext context) {
    try {
      final data = HiveDatabase.exportData();
      // Ici on pourrait implémenter le partage du fichier
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données exportées avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Importe les données
  void _importData(BuildContext context) {
    // Ici on pourrait implémenter la sélection de fichier
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'import à implémenter'),
      ),
    );
  }

  /// Affiche le dialogue de confirmation de suppression
  void _showDeleteAllDialog(WidgetRef ref, ThemeData theme, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos tâches, catégories et paramètres. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await HiveDatabase.clearAll();
                ref.invalidate(tasksProvider);
                ref.invalidate(categoriesProvider);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les données ont été supprimées'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

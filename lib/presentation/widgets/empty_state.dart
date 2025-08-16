import 'package:flutter/material.dart';

/// Widget pour afficher un état vide avec illustration et action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Widget? customIllustration;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.customIllustration,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            customIllustration ?? _buildDefaultIllustration(theme),
            
            const SizedBox(height: 32),
            
            // Titre
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit l'illustration par défaut
  Widget _buildDefaultIllustration(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: effectiveIconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: effectiveIconColor,
      ),
    );
  }
}

/// États vides prédéfinis pour différentes situations
class EmptyStates {
  /// État vide pour les tâches d'aujourd'hui
  static EmptyState todayTasks({VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.today_outlined,
      title: 'Aucune tâche aujourd\'hui',
      description: 'Profitez de cette journée libre ou ajoutez une nouvelle tâche pour rester productif.',
      actionLabel: 'Ajouter une tâche',
      onActionPressed: onAddTask,
    );
  }

  /// État vide pour les tâches de la semaine
  static EmptyState weekTasks({VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.view_week_outlined,
      title: 'Aucune tâche cette semaine',
      description: 'Planifiez votre semaine en ajoutant vos premières tâches.',
      actionLabel: 'Planifier ma semaine',
      onActionPressed: onAddTask,
    );
  }

  /// État vide pour toutes les tâches
  static EmptyState allTasks({VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.checklist_outlined,
      title: 'Aucune tâche créée',
      description: 'Commencez à organiser votre vie en créant votre première tâche.',
      actionLabel: 'Créer ma première tâche',
      onActionPressed: onAddTask,
    );
  }

  /// État vide pour les résultats de recherche
  static EmptyState searchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Aucun résultat',
      description: query != null
          ? 'Aucune tâche ne correspond à "$query". Essayez avec d\'autres mots-clés.'
          : 'Aucune tâche ne correspond à votre recherche.',
      iconColor: Colors.grey,
    );
  }

  /// État vide pour les catégories
  static EmptyState categories({VoidCallback? onAddCategory}) {
    return EmptyState(
      icon: Icons.category_outlined,
      title: 'Aucune catégorie',
      description: 'Organisez vos tâches en créant des catégories personnalisées.',
      actionLabel: 'Créer une catégorie',
      onActionPressed: onAddCategory,
    );
  }

  /// État vide pour les tâches filtrées
  static EmptyState filteredTasks({VoidCallback? onClearFilters}) {
    return EmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'Aucune tâche trouvée',
      description: 'Aucune tâche ne correspond aux filtres appliqués. Essayez de modifier vos critères.',
      actionLabel: 'Effacer les filtres',
      onActionPressed: onClearFilters,
      iconColor: Colors.orange,
    );
  }

  /// État vide pour les tâches terminées
  static EmptyState completedTasks() {
    return const EmptyState(
      icon: Icons.task_alt_rounded,
      title: 'Aucune tâche terminée',
      description: 'Les tâches que vous marquerez comme terminées apparaîtront ici.',
      iconColor: Colors.green,
    );
  }

  /// État vide pour les tâches en retard
  static EmptyState overdueTasks() {
    return const EmptyState(
      icon: Icons.schedule_rounded,
      title: 'Aucune tâche en retard',
      description: 'Excellent ! Vous êtes à jour avec toutes vos tâches.',
      iconColor: Colors.green,
    );
  }

  /// État vide pour les notifications
  static EmptyState notifications() {
    return const EmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'Aucune notification',
      description: 'Vos rappels et notifications apparaîtront ici.',
    );
  }

  /// État d'erreur générique
  static EmptyState error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Une erreur s\'est produite',
      description: message ?? 'Impossible de charger les données. Veuillez réessayer.',
      actionLabel: 'Réessayer',
      onActionPressed: onRetry,
      iconColor: Colors.red,
    );
  }

  /// État de chargement (avec animation)
  static Widget loading({String? message}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// État de maintenance
  static EmptyState maintenance() {
    return const EmptyState(
      icon: Icons.build_rounded,
      title: 'Maintenance en cours',
      description: 'Cette fonctionnalité est temporairement indisponible. Veuillez réessayer plus tard.',
      iconColor: Colors.orange,
    );
  }

  /// État hors ligne
  static EmptyState offline({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Hors ligne',
      description: 'Vérifiez votre connexion internet et réessayez.',
      actionLabel: 'Réessayer',
      onActionPressed: onRetry,
      iconColor: Colors.grey,
    );
  }
}

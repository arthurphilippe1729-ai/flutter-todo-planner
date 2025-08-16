import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/timezone_service.dart';
import '../../theme/color_schemes.dart';
import '../widgets/empty_state.dart';

/// Page de détail d'une tâche
class TaskDetailPage extends ConsumerWidget {
  final String taskId;

  const TaskDetailPage({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final task = ref.watch(taskByIdProvider(taskId));
    final categories = ref.watch(activeCategoriesProvider);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tâche introuvable'),
        ),
        body: EmptyStates.error(
          message: 'Cette tâche n\'existe pas ou a été supprimée.',
          onRetry: () => context.pop(),
        ),
      );
    }

    final category = _getCategoryForTask(task, categories);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(task, category, theme, ref, context),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations principales
              _buildMainInfo(task, category, theme),
              
              const SizedBox(height: 24),
              
              // Checklist
              if (task.hasChecklist) ...[
                _buildChecklist(task, ref, theme),
                const SizedBox(height: 24),
              ],
              
              // Rappels
              if (task.hasReminders) ...[
                _buildReminders(task, theme),
                const SizedBox(height: 24),
              ],
              
              // Récurrence
              if (task.isRecurrent) ...[
                _buildRecurrence(task, theme),
                const SizedBox(height: 24),
              ],
              
              // Tags
              if (task.tags.isNotEmpty) ...[
                _buildTags(task, theme),
                const SizedBox(height: 24),
              ],
              
              // Métadonnées
              _buildMetadata(task, theme),
              
              const SizedBox(height: 80), // Espace pour les actions
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActions(task, theme, context),
    );
  }

  /// Construit l'AppBar avec les actions
  Widget _buildAppBar(Task task, Category? category, ThemeData theme, WidgetRef ref, BuildContext context) {
    final color = category?.color ?? TaskPriorityColors.getColor(task.priority.value);
    
    return SliverAppBar.large(
      backgroundColor: color.withOpacity(0.1),
      surfaceTintColor: color,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(task.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Priorité
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TaskPriorityColors.getColorWithOpacity(task.priority.value, 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: TaskPriorityColors.getColor(task.priority.value),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Marquer comme terminé/non terminé
        IconButton(
          onPressed: () => _toggleTaskStatus(task, ref),
          icon: Icon(
            task.isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
            color: task.isCompleted ? Colors.green : null,
          ),
        ),
        
        // Menu d'actions
        PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, task, ref, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy_outlined),
                title: Text('Dupliquer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit les informations principales
  Widget _buildMainInfo(Task task, Category? category, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Horaires
            Text(
              'Horaires',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  task.isAllDay
                      ? 'Toute la journée'
                      : '${TimezoneService.formatTime(task.startAt)} - ${TimezoneService.formatTime(task.endAt)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  TimezoneService.formatRelativeDate(task.startAt),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            
            // Catégorie
            if (category != null) ...[
              const SizedBox(height: 16),
              Text(
                'Catégorie',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: category.lightColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: category.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: category.darkColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit la section checklist
  Widget _buildChecklist(Task task, WidgetRef ref, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Checklist',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${task.completedSubtasks}/${task.checklist.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Barre de progression
            LinearProgressIndicator(
              value: task.checklistProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des sous-tâches
            ...task.checklist.map((subtask) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: subtask.done,
                      onChanged: (value) {
                        // TODO: Implémenter la mise à jour des sous-tâches
                      },
                    ),
                    Expanded(
                      child: Text(
                        subtask.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: subtask.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.done
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Construit la section rappels
  Widget _buildReminders(Task task, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rappels',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...task.reminders.map((minutes) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatReminderTime(minutes),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Construit la section récurrence
  Widget _buildRecurrence(Task task, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récurrence',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  task.recurrenceRule ?? 'Récurrence personnalisée',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (task.recurrenceEndsAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jusqu\'au ${TimezoneService.formatRelativeDate(task.recurrenceEndsAt!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit la section tags
  Widget _buildTags(Task task, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: task.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les métadonnées
  Widget _buildMetadata(Task task, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow(
              'Créée le',
              TimezoneService.formatDateTime(task.createdAt),
              theme,
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Modifiée le',
              TimezoneService.formatDateTime(task.updatedAt),
              theme,
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Durée',
              _formatDuration(task.duration),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne de métadonnées
  Widget _buildMetadataRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// Construit les actions flottantes
  Widget _buildFloatingActions(Task task, ThemeData theme, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Modifier
        FloatingActionButton(
          heroTag: 'edit',
          onPressed: () => _editTask(task, context),
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.edit_rounded),
        ),
        
        const SizedBox(height: 12),
        
        // Marquer comme terminé/non terminé
        FloatingActionButton.extended(
          heroTag: 'toggle',
          onPressed: () => _toggleTaskStatus(task, null),
          backgroundColor: task.isCompleted
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.green,
          foregroundColor: task.isCompleted
              ? theme.colorScheme.onSurface
              : Colors.white,
          icon: Icon(
            task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          ),
          label: Text(
            task.isCompleted ? 'Rouvrir' : 'Terminer',
          ),
        ),
      ],
    );
  }

  /// Obtient la catégorie d'une tâche
  Category? _getCategoryForTask(Task task, List<Category> categories) {
    if (task.categoryId == null) return null;
    try {
      return categories.firstWhere((cat) => cat.id == task.categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient la couleur du statut
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  /// Formate le temps de rappel
  String _formatReminderTime(int minutes) {
    if (minutes == 0) {
      return 'À l\'heure de début';
    } else if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''} avant';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''} avant';
      } else {
        return '${hours}h${remainingMinutes}min avant';
      }
    }
  }

  /// Formate la durée
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours == 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else if (minutes == 0) {
      return '$hours heure${hours > 1 ? 's' : ''}';
    } else {
      return '${hours}h${minutes}min';
    }
  }

  /// Bascule le statut de la tâche
  void _toggleTaskStatus(Task task, WidgetRef? ref) {
    // TODO: Implémenter le basculement du statut
  }

  /// Modifie la tâche
  void _editTask(Task task, BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    if (location.contains('/today/')) {
      context.go('/today/edit/${task.id}');
    } else if (location.contains('/week/')) {
      context.go('/week/edit/${task.id}');
    } else {
      context.go('/tasks/edit/${task.id}');
    }
  }

  /// Gère les actions du menu
  void _handleAction(String action, Task task, WidgetRef ref, BuildContext context) {
    switch (action) {
      case 'edit':
        _editTask(task, context);
        break;
      case 'duplicate':
        // TODO: Implémenter la duplication
        break;
      case 'delete':
        _showDeleteDialog(task, ref, context);
        break;
    }
  }

  /// Affiche le dialogue de suppression
  void _showDeleteDialog(Task task, WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(tasksProvider.notifier).deleteTask(task.id);
              Navigator.of(context).pop();
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

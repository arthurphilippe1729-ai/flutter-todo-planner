import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../services/timezone_service.dart';
import '../../theme/color_schemes.dart';

/// Widget de carte pour afficher une tâche
class TaskCard extends StatelessWidget {
  final Task task;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final bool showTime;
  final bool compact;

  const TaskCard({
    super.key,
    required this.task,
    this.category,
    this.onTap,
    this.onEdit,
    this.onToggle,
    this.showTime = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: task.isCompleted ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: task.isOverdue && !task.isCompleted
                ? Border.all(color: colorScheme.error, width: 1)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec checkbox et actions
              Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? TaskPriorityColors.getColor(task.priority.value)
                              : colorScheme.outline,
                          width: 2,
                        ),
                        color: task.isCompleted
                            ? TaskPriorityColors.getColor(task.priority.value)
                            : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Titre et statut
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Indicateurs de statut
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          _buildStatusIndicators(theme),
                        ],
                      ],
                    ),
                  ),
                  
                  // Actions
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              
              // Description
              if (task.description != null && task.description!.isNotEmpty && !compact) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Métadonnées
              if (!compact) ...[
                const SizedBox(height: 12),
                _buildMetadata(theme),
              ],
              
              // Checklist preview
              if (task.hasChecklist && !compact) ...[
                const SizedBox(height: 8),
                _buildChecklistPreview(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit les indicateurs de statut
  Widget _buildStatusIndicators(ThemeData theme) {
    final indicators = <Widget>[];
    
    // Priorité
    if (task.priority != TaskPriority.medium) {
      indicators.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: TaskPriorityColors.getColorWithOpacity(task.priority.value, 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            task.priority.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: TaskPriorityColors.getColor(task.priority.value),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    // Récurrence
    if (task.isRecurrent) {
      indicators.add(
        Icon(
          Icons.repeat_rounded,
          size: 14,
          color: theme.colorScheme.primary,
        ),
      );
    }
    
    // Rappels
    if (task.hasReminders) {
      indicators.add(
        Icon(
          Icons.notifications_outlined,
          size: 14,
          color: theme.colorScheme.secondary,
        ),
      );
    }
    
    // En retard
    if (task.isOverdue && !task.isCompleted) {
      indicators.add(
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: theme.colorScheme.error,
        ),
      );
    }
    
    if (indicators.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: indicators
          .expand((widget) => [widget, const SizedBox(width: 8)])
          .take(indicators.length * 2 - 1)
          .toList(),
    );
  }

  /// Construit les métadonnées (heure, catégorie, tags)
  Widget _buildMetadata(ThemeData theme) {
    final metadata = <Widget>[];
    
    // Heure
    if (showTime) {
      final timeText = task.isAllDay
          ? 'Toute la journée'
          : '${TimezoneService.formatTime(task.startAt)} - ${TimezoneService.formatTime(task.endAt)}';
      
      metadata.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              timeText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    // Catégorie
    if (category != null) {
      metadata.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: category!.lightColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: category!.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: category!.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category!.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: category!.darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (metadata.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: metadata,
    );
  }

  /// Construit l'aperçu de la checklist
  Widget _buildChecklistPreview(ThemeData theme) {
    final progress = task.checklistProgress;
    final completedCount = task.completedSubtasks;
    final totalCount = task.checklist.length;
    
    return Row(
      children: [
        // Barre de progression
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Compteur
        Text(
          '$completedCount/$totalCount',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

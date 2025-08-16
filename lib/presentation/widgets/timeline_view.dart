import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../services/timezone_service.dart';
import '../../theme/color_schemes.dart';

/// Widget de vue timeline pour afficher les tâches sur une journée
class TimelineView extends StatefulWidget {
  final List<Task> tasks;
  final List<Category> categories;
  final Function(Task)? onTaskTap;
  final Function(Task)? onTaskEdit;
  final Function(Task)? onTaskToggle;
  final Function(DateTime)? onTimeSlotTap;
  final int startHour;
  final int endHour;

  const TimelineView({
    super.key,
    required this.tasks,
    required this.categories,
    this.onTaskTap,
    this.onTaskEdit,
    this.onTaskToggle,
    this.onTimeSlotTap,
    this.startHour = 0,
    this.endHour = 24,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  static const double _hourHeight = 60.0;
  static const double _timeColumnWidth = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: (widget.endHour - widget.startHour) * _hourHeight,
            child: Row(
              children: [
                // Colonne des heures
                _buildTimeColumn(theme),
                
                // Colonne des tâches
                Expanded(
                  child: _buildTasksColumn(theme),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit la colonne des heures
  Widget _buildTimeColumn(ThemeData theme) {
    return Container(
      width: _timeColumnWidth,
      child: Column(
        children: List.generate(
          widget.endHour - widget.startHour,
          (index) {
            final hour = widget.startHour + index;
            return Container(
              height: _hourHeight,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construit la colonne des tâches
  Widget _buildTasksColumn(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Lignes horizontales pour chaque heure
          ..._buildHourLines(theme),
          
          // Ligne de l'heure actuelle
          _buildCurrentTimeLine(theme),
          
          // Tâches
          ..._buildTaskBlocks(theme),
          
          // Zones cliquables pour créer des tâches
          ..._buildTimeSlots(),
        ],
      ),
    );
  }

  /// Construit les lignes horizontales pour chaque heure
  List<Widget> _buildHourLines(ThemeData theme) {
    return List.generate(
      widget.endHour - widget.startHour,
      (index) {
        final y = index * _hourHeight;
        return Positioned(
          top: y,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        );
      },
    );
  }

  /// Construit la ligne de l'heure actuelle
  Widget _buildCurrentTimeLine(ThemeData theme) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Vérifier si l'heure actuelle est dans la plage affichée
    if (currentHour < widget.startHour || currentHour >= widget.endHour) {
      return const SizedBox.shrink();
    }
    
    final y = (currentHour - widget.startHour) * _hourHeight + 
              (currentMinute / 60) * _hourHeight;
    
    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Cercle indicateur
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          
          // Ligne
          Expanded(
            child: Container(
              height: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les blocs de tâches
  List<Widget> _buildTaskBlocks(ThemeData theme) {
    final taskBlocks = <Widget>[];
    
    // Grouper les tâches qui se chevauchent
    final taskGroups = _groupOverlappingTasks();
    
    for (final group in taskGroups) {
      final groupWidth = 1.0 / group.length;
      
      for (int i = 0; i < group.length; i++) {
        final task = group[i];
        final category = _getCategoryForTask(task);
        
        final startY = _getYPositionForTime(task.startAt);
        final endY = _getYPositionForTime(task.endAt);
        final height = endY - startY;
        
        taskBlocks.add(
          Positioned(
            top: startY,
            left: i * groupWidth * MediaQuery.of(context).size.width,
            width: groupWidth * (MediaQuery.of(context).size.width - _timeColumnWidth),
            height: height,
            child: Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 2),
              child: _buildTaskBlock(task, category, theme),
            ),
          ),
        );
      }
    }
    
    return taskBlocks;
  }

  /// Construit un bloc de tâche
  Widget _buildTaskBlock(Task task, Category? category, ThemeData theme) {
    final color = category?.color ?? TaskPriorityColors.getColor(task.priority.value);
    
    return GestureDetector(
      onTap: () => widget.onTaskTap?.call(task),
      onLongPress: () => widget.onTaskEdit?.call(task),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              task.title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Heure
            if (task.duration.inMinutes >= 30) ...[
              const SizedBox(height: 2),
              Text(
                '${TimezoneService.formatTime(task.startAt)} - ${TimezoneService.formatTime(task.endAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
            
            // Indicateurs
            if (task.duration.inMinutes >= 60) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (task.isRecurrent)
                    Icon(
                      Icons.repeat_rounded,
                      size: 12,
                      color: color,
                    ),
                  if (task.hasReminders) ...[
                    if (task.isRecurrent) const SizedBox(width: 4),
                    Icon(
                      Icons.notifications_outlined,
                      size: 12,
                      color: color,
                    ),
                  ],
                  if (task.isCompleted) ...[
                    if (task.isRecurrent || task.hasReminders) const SizedBox(width: 4),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Colors.green,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit les zones cliquables pour créer des tâches
  List<Widget> _buildTimeSlots() {
    final slots = <Widget>[];
    
    for (int hour = widget.startHour; hour < widget.endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final y = (hour - widget.startHour) * _hourHeight + (minute / 60) * _hourHeight;
        
        slots.add(
          Positioned(
            top: y,
            left: 0,
            right: 0,
            height: _hourHeight / 2,
            child: GestureDetector(
              onTap: () {
                final dateTime = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  hour,
                  minute,
                );
                widget.onTimeSlotTap?.call(dateTime);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        );
      }
    }
    
    return slots;
  }

  /// Groupe les tâches qui se chevauchent
  List<List<Task>> _groupOverlappingTasks() {
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    
    final groups = <List<Task>>[];
    final processed = <Task>{};
    
    for (final task in sortedTasks) {
      if (processed.contains(task)) continue;
      
      final group = <Task>[task];
      processed.add(task);
      
      // Trouver toutes les tâches qui se chevauchent avec cette tâche
      for (final otherTask in sortedTasks) {
        if (processed.contains(otherTask)) continue;
        
        if (_tasksOverlap(task, otherTask)) {
          group.add(otherTask);
          processed.add(otherTask);
        }
      }
      
      groups.add(group);
    }
    
    return groups;
  }

  /// Vérifie si deux tâches se chevauchent
  bool _tasksOverlap(Task task1, Task task2) {
    return task1.startAt.isBefore(task2.endAt) && task2.startAt.isBefore(task1.endAt);
  }

  /// Obtient la position Y pour une heure donnée
  double _getYPositionForTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    
    if (hour < widget.startHour) return 0;
    if (hour >= widget.endHour) return (widget.endHour - widget.startHour) * _hourHeight;
    
    return (hour - widget.startHour) * _hourHeight + (minute / 60) * _hourHeight;
  }

  /// Obtient la catégorie d'une tâche
  Category? _getCategoryForTask(Task task) {
    if (task.categoryId == null) return null;
    try {
      return widget.categories.firstWhere((cat) => cat.id == task.categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Fait défiler vers l'heure actuelle
  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (currentHour >= widget.startHour && currentHour < widget.endHour) {
      final targetY = (currentHour - widget.startHour - 1) * _hourHeight;
      _scrollController.animateTo(
        targetY.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/timezone_service.dart';
import '../widgets/empty_state.dart';

/// Page de vue hebdomadaire
class WeekPage extends ConsumerStatefulWidget {
  const WeekPage({super.key});

  @override
  ConsumerState<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends ConsumerState<WeekPage> {
  late DateTime _currentWeek;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentWeek = _getStartOfWeek(DateTime.now());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thisWeekTasks = ref.watch(thisWeekTasksProvider);
    final categories = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(theme, thisWeekTasks),
          ];
        },
        body: thisWeekTasks.isEmpty
            ? EmptyStates.weekTasks(
                onAddTask: () => context.go('/week/new'),
              )
            : _buildWeekView(thisWeekTasks, categories, theme),
      ),
    );
  }

  /// Construit l'AppBar avec navigation de semaine
  Widget _buildAppBar(ThemeData theme, List<Task> weekTasks) {
    final completedTasks = weekTasks.where((task) => task.isCompleted).length;
    final totalTasks = weekTasks.length;

    return SliverAppBar.large(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getWeekTitle(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$completedTasks/$totalTasks tâches terminées',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _goToPreviousWeek,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: _goToCurrentWeek,
          icon: const Icon(Icons.today_rounded),
        ),
        IconButton(
          onPressed: _goToNextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  /// Construit la vue hebdomadaire
  Widget _buildWeekView(
    List<Task> weekTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // En-tête des jours
        _buildDaysHeader(theme),
        
        // Grille des tâches
        Expanded(
          child: _buildWeekGrid(weekTasks, categories, theme),
        ),
      ],
    );
  }

  /// Construit l'en-tête des jours de la semaine
  Widget _buildDaysHeader(ThemeData theme) {
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final today = DateTime.now();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final date = _currentWeek.add(Duration(days: index));
          final isToday = TimezoneService.isToday(date);
          
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isToday ? theme.colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    dayNames[index],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isToday 
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isToday 
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Construit la grille des tâches de la semaine
  Widget _buildWeekGrid(
    List<Task> weekTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (dayIndex) {
          final date = _currentWeek.add(Duration(days: dayIndex));
          final dayTasks = _getTasksForDay(weekTasks, date);
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: dayIndex < 6 ? 8 : 0),
              child: _buildDayColumn(date, dayTasks, categories, theme),
            ),
          );
        }),
      ),
    );
  }

  /// Construit la colonne d'un jour
  Widget _buildDayColumn(
    DateTime date,
    List<Task> dayTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    final completedTasks = dayTasks.where((task) => task.isCompleted).length;
    final totalTasks = dayTasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Column(
      children: [
        // Indicateur de progression
        if (totalTasks > 0) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedTasks/$totalTasks',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Tâches du jour
        ...dayTasks.map((task) {
          final category = _getCategoryForTask(task, categories);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildWeekTaskCard(task, category, theme),
          );
        }),
        
        // Zone pour ajouter une tâche
        GestureDetector(
          onTap: () => _createTaskForDay(date),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// Construit une carte de tâche pour la vue semaine
  Widget _buildWeekTaskCard(Task task, Category? category, ThemeData theme) {
    final color = category?.color ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () => context.go('/week/task/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              task.title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Heure
            if (!task.isAllDay) ...[
              const SizedBox(height: 4),
              Text(
                TimezoneService.formatTime(task.startAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            // Indicateurs
            const SizedBox(height: 4),
            Row(
              children: [
                // Statut
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status, theme),
                    shape: BoxShape.circle,
                  ),
                ),
                
                const Spacer(),
                
                // Priorité
                if (task.priority != TaskPriority.medium)
                  Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Obtient les tâches pour un jour donné
  List<Task> _getTasksForDay(List<Task> allTasks, DateTime date) {
    return allTasks.where((task) {
      final taskDate = DateTime(task.startAt.year, task.startAt.month, task.startAt.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
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
  Color _getStatusColor(TaskStatus status, ThemeData theme) {
    switch (status) {
      case TaskStatus.todo:
        return theme.colorScheme.outline;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  /// Obtient la couleur de la priorité
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.red.shade700;
    }
  }

  /// Obtient le début de la semaine (lundi)
  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  /// Obtient le titre de la semaine
  String _getWeekTitle() {
    final endOfWeek = _currentWeek.add(const Duration(days: 6));
    
    if (_currentWeek.month == endOfWeek.month) {
      return '${_currentWeek.day} - ${endOfWeek.day} ${_getMonthName(_currentWeek.month)}';
    } else {
      return '${_currentWeek.day} ${_getMonthName(_currentWeek.month)} - ${endOfWeek.day} ${_getMonthName(endOfWeek.month)}';
    }
  }

  /// Obtient le nom du mois
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }

  /// Va à la semaine précédente
  void _goToPreviousWeek() {
    setState(() {
      _currentWeek = _currentWeek.subtract(const Duration(days: 7));
    });
  }

  /// Va à la semaine suivante
  void _goToNextWeek() {
    setState(() {
      _currentWeek = _currentWeek.add(const Duration(days: 7));
    });
  }

  /// Va à la semaine actuelle
  void _goToCurrentWeek() {
    setState(() {
      _currentWeek = _getStartOfWeek(DateTime.now());
    });
  }

  /// Crée une tâche pour un jour spécifique
  void _createTaskForDay(DateTime date) {
    final dateTime = DateTime(date.year, date.month, date.day, 9, 0); // 9h par défaut
    context.go('/week/new', extra: {'initialDateTime': dateTime});
  }
}

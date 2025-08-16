import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/task.dart';
import '../data/repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';

part 'task_provider.g.dart';

/// Provider pour le repository des tâches
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository();
}

/// Provider pour toutes les tâches
@riverpod
class Tasks extends _$Tasks {
  @override
  List<Task> build() {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.getAllTasks();
  }

  /// Recharge les tâches depuis la base de données
  void refresh() {
    final repository = ref.read(taskRepositoryProvider);
    state = repository.getAllTasks();
  }

  /// Ajoute une nouvelle tâche
  Future<bool> addTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    final success = await repository.saveTask(task);
    
    if (success) {
      // Programmer les notifications
      await NotificationService.scheduleTaskNotification(task);
      
      // Rafraîchir la liste
      refresh();
    }
    
    return success;
  }

  /// Met à jour une tâche existante
  Future<bool> updateTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    final success = await repository.updateTask(task);
    
    if (success) {
      // Reprogrammer les notifications
      await NotificationService.scheduleTaskNotification(task);
      
      // Rafraîchir la liste
      refresh();
    }
    
    return success;
  }

  /// Supprime une tâche
  Future<bool> deleteTask(String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    
    // Annuler les notifications
    await NotificationService.cancelTaskNotifications(taskId);
    
    final success = await repository.deleteTask(taskId);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Marque une tâche comme terminée
  Future<bool> markTaskAsCompleted(String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    final success = await repository.markTaskAsCompleted(taskId);
    
    if (success) {
      // Annuler les notifications pour cette tâche
      await NotificationService.cancelTaskNotifications(taskId);
      refresh();
    }
    
    return success;
  }

  /// Marque une tâche comme en cours
  Future<bool> markTaskAsInProgress(String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    final success = await repository.markTaskAsInProgress(taskId);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Bascule le statut d'une tâche (todo <-> done)
  Future<bool> toggleTaskStatus(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    
    if (task.isCompleted) {
      return await markTaskAsInProgress(taskId);
    } else {
      return await markTaskAsCompleted(taskId);
    }
  }
}

/// Provider pour les tâches d'aujourd'hui
@riverpod
List<Task> todayTasks(TodayTasksRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final todayTasks = repository.getTodayTasks();
  
  // Inclure les occurrences récurrentes d'aujourd'hui
  final allTasks = repository.getAllTasks();
  final recurrentTasks = allTasks.where((task) => task.isRecurrent).toList();
  
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  for (final task in recurrentTasks) {
    final occurrences = RecurrenceService.getOccurrencesInRange(
      task,
      startOfDay,
      endOfDay,
    );
    
    for (final occurrence in occurrences) {
      final duration = task.endAt.difference(task.startAt);
      final occurrenceTask = task.copyWith(
        id: '${task.id}_${occurrence.millisecondsSinceEpoch}',
        startAt: occurrence,
        endAt: occurrence.add(duration),
      );
      todayTasks.add(occurrenceTask);
    }
  }
  
  // Trier par heure de début
  todayTasks.sort((a, b) => a.startAt.compareTo(b.startAt));
  
  return todayTasks;
}

/// Provider pour les tâches de cette semaine
@riverpod
List<Task> thisWeekTasks(ThisWeekTasksRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final weekTasks = repository.getThisWeekTasks();
  
  // Inclure les occurrences récurrentes de cette semaine
  final allTasks = repository.getAllTasks();
  final recurrentTasks = allTasks.where((task) => task.isRecurrent).toList();
  
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  
  for (final task in recurrentTasks) {
    final occurrences = RecurrenceService.getOccurrencesInRange(
      task,
      startOfWeek,
      endOfWeek,
    );
    
    for (final occurrence in occurrences) {
      final duration = task.endAt.difference(task.startAt);
      final occurrenceTask = task.copyWith(
        id: '${task.id}_${occurrence.millisecondsSinceEpoch}',
        startAt: occurrence,
        endAt: occurrence.add(duration),
      );
      weekTasks.add(occurrenceTask);
    }
  }
  
  // Trier par date puis par heure
  weekTasks.sort((a, b) => a.startAt.compareTo(b.startAt));
  
  return weekTasks;
}

/// Provider pour les tâches en retard
@riverpod
List<Task> overdueTasks(OverdueTasksRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getOverdueTasks();
}

/// Provider pour les tâches par statut
@riverpod
List<Task> tasksByStatus(TasksByStatusRef ref, TaskStatus status) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasksByStatus(status);
}

/// Provider pour les tâches par priorité
@riverpod
List<Task> tasksByPriority(TasksByPriorityRef ref, TaskPriority priority) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasksByPriority(priority);
}

/// Provider pour les tâches par catégorie
@riverpod
List<Task> tasksByCategory(TasksByCategoryRef ref, String categoryId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasksByCategory(categoryId);
}

/// Provider pour la recherche de tâches
@riverpod
class TaskSearch extends _$TaskSearch {
  @override
  List<Task> build() {
    return [];
  }

  /// Recherche des tâches par query
  void search(String query) {
    final repository = ref.read(taskRepositoryProvider);
    state = repository.searchTasks(query);
  }

  /// Efface la recherche
  void clear() {
    state = [];
  }
}

/// Provider pour les filtres de tâches
@riverpod
class TaskFilters extends _$TaskFilters {
  @override
  TaskFilterState build() {
    return const TaskFilterState();
  }

  /// Met à jour les filtres
  void updateFilters({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurrent,
    bool? hasReminders,
  }) {
    state = state.copyWith(
      status: status,
      priority: priority,
      categoryId: categoryId,
      tags: tags,
      startDate: startDate,
      endDate: endDate,
      isRecurrent: isRecurrent,
      hasReminders: hasReminders,
    );
  }

  /// Efface tous les filtres
  void clearFilters() {
    state = const TaskFilterState();
  }

  /// Applique les filtres aux tâches
  List<Task> applyFilters(List<Task> tasks) {
    final repository = ref.read(taskRepositoryProvider);
    
    return repository.filterTasks(
      status: state.status,
      priority: state.priority,
      categoryId: state.categoryId,
      tags: state.tags,
      startDate: state.startDate,
      endDate: state.endDate,
      isRecurrent: state.isRecurrent,
      hasReminders: state.hasReminders,
    );
  }
}

/// Provider pour les tâches filtrées
@riverpod
List<Task> filteredTasks(FilteredTasksRef ref) {
  final allTasks = ref.watch(tasksProvider);
  final filters = ref.watch(taskFiltersProvider);
  
  if (filters.isEmpty) {
    return allTasks;
  }
  
  final filtersNotifier = ref.read(taskFiltersProvider.notifier);
  return filtersNotifier.applyFilters(allTasks);
}

/// Provider pour le tri des tâches
@riverpod
class TaskSort extends _$TaskSort {
  @override
  TaskSortState build() {
    return const TaskSortState();
  }

  /// Change le type de tri
  void setSortType(TaskSortType sortType) {
    state = state.copyWith(sortType: sortType);
  }

  /// Bascule l'ordre de tri
  void toggleSortOrder() {
    state = state.copyWith(ascending: !state.ascending);
  }

  /// Applique le tri aux tâches
  List<Task> sortTasks(List<Task> tasks) {
    final repository = ref.read(taskRepositoryProvider);
    final sortedTasks = repository.sortTasks(tasks, state.sortType);
    
    return state.ascending ? sortedTasks : sortedTasks.reversed.toList();
  }
}

/// Provider pour les tâches triées
@riverpod
List<Task> sortedTasks(SortedTasksRef ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  final sortNotifier = ref.read(taskSortProvider.notifier);
  
  return sortNotifier.sortTasks(filteredTasks);
}

/// Provider pour les statistiques des tâches
@riverpod
TaskStats taskStats(TaskStatsRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskStats();
}

/// Provider pour tous les tags utilisés
@riverpod
List<String> allTags(AllTagsRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getAllTags();
}

/// Provider pour une tâche spécifique
@riverpod
Task? taskById(TaskByIdRef ref, String taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskById(taskId);
}

/// État des filtres de tâches
class TaskFilterState {
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? categoryId;
  final List<String>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isRecurrent;
  final bool? hasReminders;

  const TaskFilterState({
    this.status,
    this.priority,
    this.categoryId,
    this.tags,
    this.startDate,
    this.endDate,
    this.isRecurrent,
    this.hasReminders,
  });

  /// Vérifie si les filtres sont vides
  bool get isEmpty {
    return status == null &&
           priority == null &&
           categoryId == null &&
           (tags == null || tags!.isEmpty) &&
           startDate == null &&
           endDate == null &&
           isRecurrent == null &&
           hasReminders == null;
  }

  /// Copie avec de nouveaux paramètres
  TaskFilterState copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurrent,
    bool? hasReminders,
  }) {
    return TaskFilterState(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      hasReminders: hasReminders ?? this.hasReminders,
    );
  }
}

/// État du tri des tâches
class TaskSortState {
  final TaskSortType sortType;
  final bool ascending;

  const TaskSortState({
    this.sortType = TaskSortType.date,
    this.ascending = true,
  });

  /// Copie avec de nouveaux paramètres
  TaskSortState copyWith({
    TaskSortType? sortType,
    bool? ascending,
  }) {
    return TaskSortState(
      sortType: sortType ?? this.sortType,
      ascending: ascending ?? this.ascending,
    );
  }
}

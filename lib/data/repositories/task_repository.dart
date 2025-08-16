import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../models/task.dart';
import '../database/hive_database.dart';

/// Repository pour la gestion des tâches
class TaskRepository {
  late final Box<Task> _box;

  TaskRepository() {
    _box = HiveDatabase.tasksBox;
  }

  /// Obtient toutes les tâches
  List<Task> getAllTasks() {
    try {
      return _box.values.toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches: $e');
      return [];
    }
  }

  /// Obtient une tâche par son ID
  Task? getTaskById(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la tâche $id: $e');
      return null;
    }
  }

  /// Obtient les tâches d'une date spécifique
  List<Task> getTasksByDate(DateTime date) {
    try {
      final targetDate = DateTime(date.year, date.month, date.day);
      return _box.values.where((task) {
        final taskDate = DateTime(task.startAt.year, task.startAt.month, task.startAt.day);
        return taskDate.isAtSameMomentAs(targetDate);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches du ${date.toString()}: $e');
      return [];
    }
  }

  /// Obtient les tâches d'une plage de dates
  List<Task> getTasksByDateRange(DateTime startDate, DateTime endDate) {
    try {
      return _box.values.where((task) {
        return task.startAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
               task.startAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches entre ${startDate.toString()} et ${endDate.toString()}: $e');
      return [];
    }
  }

  /// Obtient les tâches d'aujourd'hui
  List<Task> getTodayTasks() {
    return getTasksByDate(DateTime.now());
  }

  /// Obtient les tâches de cette semaine
  List<Task> getThisWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getTasksByDateRange(startOfWeek, endOfWeek);
  }

  /// Obtient les tâches par statut
  List<Task> getTasksByStatus(TaskStatus status) {
    try {
      return _box.values.where((task) => task.status == status).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches avec le statut $status: $e');
      return [];
    }
  }

  /// Obtient les tâches par priorité
  List<Task> getTasksByPriority(TaskPriority priority) {
    try {
      return _box.values.where((task) => task.priority == priority).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches avec la priorité $priority: $e');
      return [];
    }
  }

  /// Obtient les tâches par catégorie
  List<Task> getTasksByCategory(String categoryId) {
    try {
      return _box.values.where((task) => task.categoryId == categoryId).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches de la catégorie $categoryId: $e');
      return [];
    }
  }

  /// Obtient les tâches récurrentes
  List<Task> getRecurrentTasks() {
    try {
      return _box.values.where((task) => task.isRecurrent).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches récurrentes: $e');
      return [];
    }
  }

  /// Obtient les tâches en retard
  List<Task> getOverdueTasks() {
    try {
      return _box.values.where((task) => task.isOverdue).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tâches en retard: $e');
      return [];
    }
  }

  /// Recherche des tâches par texte
  List<Task> searchTasks(String query) {
    try {
      if (query.isEmpty) return getAllTasks();
      
      final lowerQuery = query.toLowerCase();
      return _box.values.where((task) {
        return task.title.toLowerCase().contains(lowerQuery) ||
               (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
               task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de tâches avec "$query": $e');
      return [];
    }
  }

  /// Filtre les tâches selon plusieurs critères
  List<Task> filterTasks({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurrent,
    bool? hasReminders,
  }) {
    try {
      var tasks = _box.values.toList();

      if (status != null) {
        tasks = tasks.where((task) => task.status == status).toList();
      }

      if (priority != null) {
        tasks = tasks.where((task) => task.priority == priority).toList();
      }

      if (categoryId != null) {
        tasks = tasks.where((task) => task.categoryId == categoryId).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        tasks = tasks.where((task) {
          return tags.any((tag) => task.tags.contains(tag));
        }).toList();
      }

      if (startDate != null) {
        tasks = tasks.where((task) => task.startAt.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
      }

      if (endDate != null) {
        tasks = tasks.where((task) => task.startAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }

      if (isRecurrent != null) {
        tasks = tasks.where((task) => task.isRecurrent == isRecurrent).toList();
      }

      if (hasReminders != null) {
        tasks = tasks.where((task) => task.hasReminders == hasReminders).toList();
      }

      return tasks;
    } catch (e) {
      debugPrint('❌ Erreur lors du filtrage des tâches: $e');
      return [];
    }
  }

  /// Trie les tâches
  List<Task> sortTasks(List<Task> tasks, TaskSortType sortType) {
    try {
      final sortedTasks = List<Task>.from(tasks);
      
      switch (sortType) {
        case TaskSortType.date:
          sortedTasks.sort((a, b) => a.compareByDate(b));
          break;
        case TaskSortType.priority:
          sortedTasks.sort((a, b) => a.compareByPriority(b));
          break;
        case TaskSortType.title:
          sortedTasks.sort((a, b) => a.compareByTitle(b));
          break;
        case TaskSortType.status:
          sortedTasks.sort((a, b) => a.status.index.compareTo(b.status.index));
          break;
        case TaskSortType.category:
          sortedTasks.sort((a, b) => (a.categoryId ?? '').compareTo(b.categoryId ?? ''));
          break;
        case TaskSortType.createdAt:
          sortedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case TaskSortType.updatedAt:
          sortedTasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
      }
      
      return sortedTasks;
    } catch (e) {
      debugPrint('❌ Erreur lors du tri des tâches: $e');
      return tasks;
    }
  }

  /// Sauvegarde une tâche
  Future<bool> saveTask(Task task) async {
    try {
      await _box.put(task.id, task);
      debugPrint('✅ Tâche "${task.title}" sauvegardée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde de la tâche "${task.title}": $e');
      return false;
    }
  }

  /// Met à jour une tâche
  Future<bool> updateTask(Task task) async {
    try {
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      await _box.put(updatedTask.id, updatedTask);
      debugPrint('✅ Tâche "${task.title}" mise à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de la tâche "${task.title}": $e');
      return false;
    }
  }

  /// Supprime une tâche
  Future<bool> deleteTask(String taskId) async {
    try {
      final task = _box.get(taskId);
      await _box.delete(taskId);
      debugPrint('✅ Tâche "${task?.title ?? taskId}" supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la tâche $taskId: $e');
      return false;
    }
  }

  /// Supprime plusieurs tâches
  Future<bool> deleteTasks(List<String> taskIds) async {
    try {
      await _box.deleteAll(taskIds);
      debugPrint('✅ ${taskIds.length} tâches supprimées');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de ${taskIds.length} tâches: $e');
      return false;
    }
  }

  /// Marque une tâche comme terminée
  Future<bool> markTaskAsCompleted(String taskId) async {
    try {
      final task = _box.get(taskId);
      if (task != null) {
        final completedTask = task.markAsCompleted();
        await _box.put(taskId, completedTask);
        debugPrint('✅ Tâche "${task.title}" marquée comme terminée');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage de la tâche $taskId comme terminée: $e');
      return false;
    }
  }

  /// Marque une tâche comme en cours
  Future<bool> markTaskAsInProgress(String taskId) async {
    try {
      final task = _box.get(taskId);
      if (task != null) {
        final inProgressTask = task.markAsInProgress();
        await _box.put(taskId, inProgressTask);
        debugPrint('✅ Tâche "${task.title}" marquée comme en cours');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage de la tâche $taskId comme en cours: $e');
      return false;
    }
  }

  /// Obtient les statistiques des tâches
  TaskStats getTaskStats() {
    try {
      final allTasks = getAllTasks();
      final todayTasks = getTodayTasks();
      final thisWeekTasks = getThisWeekTasks();
      
      return TaskStats(
        totalTasks: allTasks.length,
        completedTasks: allTasks.where((task) => task.isCompleted).length,
        inProgressTasks: allTasks.where((task) => task.isInProgress).length,
        todoTasks: allTasks.where((task) => task.status == TaskStatus.todo).length,
        overdueTasks: getOverdueTasks().length,
        todayTasks: todayTasks.length,
        todayCompletedTasks: todayTasks.where((task) => task.isCompleted).length,
        thisWeekTasks: thisWeekTasks.length,
        thisWeekCompletedTasks: thisWeekTasks.where((task) => task.isCompleted).length,
        recurrentTasks: getRecurrentTasks().length,
        tasksWithReminders: allTasks.where((task) => task.hasReminders).length,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul des statistiques: $e');
      return TaskStats.empty();
    }
  }

  /// Écoute les changements dans la box
  Stream<BoxEvent> watchTasks() {
    return _box.watch();
  }

  /// Obtient tous les tags utilisés
  List<String> getAllTags() {
    try {
      final allTags = <String>{};
      for (final task in _box.values) {
        allTags.addAll(task.tags);
      }
      return allTags.toList()..sort();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tags: $e');
      return [];
    }
  }
}

/// Énumération pour les types de tri
enum TaskSortType {
  date,
  priority,
  title,
  status,
  category,
  createdAt,
  updatedAt,
}

/// Classe pour les statistiques des tâches
class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int todoTasks;
  final int overdueTasks;
  final int todayTasks;
  final int todayCompletedTasks;
  final int thisWeekTasks;
  final int thisWeekCompletedTasks;
  final int recurrentTasks;
  final int tasksWithReminders;

  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.todoTasks,
    required this.overdueTasks,
    required this.todayTasks,
    required this.todayCompletedTasks,
    required this.thisWeekTasks,
    required this.thisWeekCompletedTasks,
    required this.recurrentTasks,
    required this.tasksWithReminders,
  });

  factory TaskStats.empty() {
    return const TaskStats(
      totalTasks: 0,
      completedTasks: 0,
      inProgressTasks: 0,
      todoTasks: 0,
      overdueTasks: 0,
      todayTasks: 0,
      todayCompletedTasks: 0,
      thisWeekTasks: 0,
      thisWeekCompletedTasks: 0,
      recurrentTasks: 0,
      tasksWithReminders: 0,
    );
  }

  /// Pourcentage de tâches terminées
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  /// Pourcentage de tâches terminées aujourd'hui
  double get todayCompletionRate {
    if (todayTasks == 0) return 0.0;
    return todayCompletedTasks / todayTasks;
  }

  /// Pourcentage de tâches terminées cette semaine
  double get thisWeekCompletionRate {
    if (thisWeekTasks == 0) return 0.0;
    return thisWeekCompletedTasks / thisWeekTasks;
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'subtask.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Énumération pour le statut d'une tâche
@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  todo('todo'),
  @HiveField(1)
  inProgress('in_progress'),
  @HiveField(2)
  done('done');

  const TaskStatus(this.value);
  final String value;

  /// Obtient le libellé français du statut
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.done:
        return 'Terminé';
    }
  }

  /// Obtient la couleur associée au statut
  String get colorHex {
    switch (this) {
      case TaskStatus.todo:
        return '#6750A4'; // Primary
      case TaskStatus.inProgress:
        return '#FF9800'; // Orange
      case TaskStatus.done:
        return '#4CAF50'; // Vert
    }
  }

  /// Crée un TaskStatus depuis une string
  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// Énumération pour la priorité d'une tâche
@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0)
  low('low'),
  @HiveField(1)
  medium('medium'),
  @HiveField(2)
  high('high'),
  @HiveField(3)
  urgent('urgent');

  const TaskPriority(this.value);
  final String value;

  /// Obtient le libellé français de la priorité
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Faible';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Élevée';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  /// Obtient la couleur associée à la priorité
  String get colorHex {
    switch (this) {
      case TaskPriority.low:
        return '#4CAF50'; // Vert
      case TaskPriority.medium:
        return '#FF9800'; // Orange
      case TaskPriority.high:
        return '#FF5722'; // Rouge-orange
      case TaskPriority.urgent:
        return '#D32F2F'; // Rouge
    }
  }

  /// Obtient la valeur numérique pour le tri
  int get sortValue {
    switch (this) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
      case TaskPriority.urgent:
        return 4;
    }
  }

  /// Crée un TaskPriority depuis une string
  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Modèle principal pour une tâche
@freezed
@HiveType(typeId: 0)
class Task with _$Task {
  const factory Task({
    /// Identifiant unique de la tâche (UUID)
    @HiveField(0) required String id,
    
    /// Titre de la tâche
    @HiveField(1) required String title,
    
    /// Description optionnelle de la tâche
    @HiveField(2) String? description,
    
    /// Date et heure de début (TZ-aware)
    @HiveField(3) required DateTime startAt,
    
    /// Date et heure de fin (TZ-aware)
    @HiveField(4) required DateTime endAt,
    
    /// Indique si la tâche dure toute la journée
    @HiveField(5) @Default(false) bool isAllDay,
    
    /// Règle de récurrence au format RRULE
    @HiveField(6) String? recurrenceRule,
    
    /// Date de fin de la récurrence
    @HiveField(7) DateTime? recurrenceEndsAt,
    
    /// Liste des rappels (en minutes avant le début)
    @HiveField(8) @Default([]) List<int> reminders,
    
    /// Statut de la tâche
    @HiveField(9) @Default(TaskStatus.todo) TaskStatus status,
    
    /// Priorité de la tâche
    @HiveField(10) @Default(TaskPriority.medium) TaskPriority priority,
    
    /// Identifiant de la catégorie
    @HiveField(11) String? categoryId,
    
    /// Liste des tags
    @HiveField(12) @Default([]) List<String> tags,
    
    /// Liste des sous-tâches
    @HiveField(13) @Default([]) List<Subtask> checklist,
    
    /// Date de création
    @HiveField(14) required DateTime createdAt,
    
    /// Date de dernière modification
    @HiveField(15) required DateTime updatedAt,
  }) = _Task;

  const Task._();

  /// Crée une tâche depuis JSON
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  /// Crée une nouvelle tâche avec des valeurs par défaut
  factory Task.create({
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    String? description,
    bool isAllDay = false,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    List<String> tags = const [],
    List<int> reminders = const [],
  }) {
    final now = DateTime.now();
    return Task(
      id: _generateId(),
      title: title,
      description: description,
      startAt: startAt,
      endAt: endAt,
      isAllDay: isAllDay,
      priority: priority,
      categoryId: categoryId,
      tags: tags,
      reminders: reminders,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Génère un ID unique pour la tâche
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  /// Durée de la tâche
  Duration get duration => endAt.difference(startAt);

  /// Indique si la tâche est terminée
  bool get isCompleted => status == TaskStatus.done;

  /// Indique si la tâche est en cours
  bool get isInProgress => status == TaskStatus.inProgress;

  /// Indique si la tâche est récurrente
  bool get isRecurrent => recurrenceRule != null && recurrenceRule!.isNotEmpty;

  /// Indique si la tâche a des rappels
  bool get hasReminders => reminders.isNotEmpty;

  /// Indique si la tâche a une checklist
  bool get hasChecklist => checklist.isNotEmpty;

  /// Nombre de sous-tâches terminées
  int get completedSubtasks => checklist.where((subtask) => subtask.done).length;

  /// Pourcentage de progression de la checklist
  double get checklistProgress {
    if (checklist.isEmpty) return 0.0;
    return completedSubtasks / checklist.length;
  }

  /// Indique si la tâche est en retard
  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(endAt);
  }

  /// Indique si la tâche commence aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(startAt.year, startAt.month, startAt.day);
    return taskDay.isAtSameMomentAs(today);
  }

  /// Indique si la tâche commence demain
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDay = DateTime(startAt.year, startAt.month, startAt.day);
    return taskDay.isAtSameMomentAs(tomorrow);
  }

  /// Indique si la tâche est dans la semaine courante
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return startAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           startAt.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Obtient le prochain rappel à déclencher
  DateTime? get nextReminder {
    if (!hasReminders) return null;
    
    final now = DateTime.now();
    for (final reminderMinutes in reminders.reversed) {
      final reminderTime = startAt.subtract(Duration(minutes: reminderMinutes));
      if (reminderTime.isAfter(now)) {
        return reminderTime;
      }
    }
    return null;
  }

  /// Marque la tâche comme terminée
  Task markAsCompleted() {
    return copyWith(
      status: TaskStatus.done,
      updatedAt: DateTime.now(),
    );
  }

  /// Marque la tâche comme en cours
  Task markAsInProgress() {
    return copyWith(
      status: TaskStatus.inProgress,
      updatedAt: DateTime.now(),
    );
  }

  /// Marque la tâche comme à faire
  Task markAsTodo() {
    return copyWith(
      status: TaskStatus.todo,
      updatedAt: DateTime.now(),
    );
  }

  /// Ajoute une sous-tâche
  Task addSubtask(String text) {
    final newSubtask = Subtask.create(text: text);
    return copyWith(
      checklist: [...checklist, newSubtask],
      updatedAt: DateTime.now(),
    );
  }

  /// Met à jour une sous-tâche
  Task updateSubtask(String subtaskId, {String? text, bool? done}) {
    final updatedChecklist = checklist.map((subtask) {
      if (subtask.id == subtaskId) {
        return subtask.copyWith(
          text: text ?? subtask.text,
          done: done ?? subtask.done,
        );
      }
      return subtask;
    }).toList();

    return copyWith(
      checklist: updatedChecklist,
      updatedAt: DateTime.now(),
    );
  }

  /// Supprime une sous-tâche
  Task removeSubtask(String subtaskId) {
    final updatedChecklist = checklist
        .where((subtask) => subtask.id != subtaskId)
        .toList();

    return copyWith(
      checklist: updatedChecklist,
      updatedAt: DateTime.now(),
    );
  }

  /// Ajoute un tag
  Task addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(
      tags: [...tags, tag],
      updatedAt: DateTime.now(),
    );
  }

  /// Supprime un tag
  Task removeTag(String tag) {
    return copyWith(
      tags: tags.where((t) => t != tag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Ajoute un rappel
  Task addReminder(int minutes) {
    if (reminders.contains(minutes)) return this;
    final sortedReminders = [...reminders, minutes]..sort((a, b) => b.compareTo(a));
    return copyWith(
      reminders: sortedReminders,
      updatedAt: DateTime.now(),
    );
  }

  /// Supprime un rappel
  Task removeReminder(int minutes) {
    return copyWith(
      reminders: reminders.where((r) => r != minutes).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Met à jour la tâche
  Task update({
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    String? recurrenceRule,
    DateTime? recurrenceEndsAt,
    List<int>? reminders,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    List<String>? tags,
    List<Subtask>? checklist,
  }) {
    return copyWith(
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceEndsAt: recurrenceEndsAt ?? this.recurrenceEndsAt,
      reminders: reminders ?? this.reminders,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      checklist: checklist ?? this.checklist,
      updatedAt: DateTime.now(),
    );
  }

  /// Compare deux tâches pour le tri par date
  int compareByDate(Task other) {
    return startAt.compareTo(other.startAt);
  }

  /// Compare deux tâches pour le tri par priorité
  int compareByPriority(Task other) {
    return other.priority.sortValue.compareTo(priority.sortValue);
  }

  /// Compare deux tâches pour le tri alphabétique
  int compareByTitle(Task other) {
    return title.toLowerCase().compareTo(other.title.toLowerCase());
  }
}

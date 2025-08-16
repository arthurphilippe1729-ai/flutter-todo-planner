import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'subtask.freezed.dart';
part 'subtask.g.dart';

/// Modèle pour une sous-tâche dans une checklist
@freezed
@HiveType(typeId: 3)
class Subtask with _$Subtask {
  const factory Subtask({
    /// Identifiant unique de la sous-tâche
    @HiveField(0) required String id,
    
    /// Texte de la sous-tâche
    @HiveField(1) required String text,
    
    /// Indique si la sous-tâche est terminée
    @HiveField(2) @Default(false) bool done,
    
    /// Date de création
    @HiveField(3) required DateTime createdAt,
    
    /// Date de dernière modification
    @HiveField(4) required DateTime updatedAt,
  }) = _Subtask;

  const Subtask._();

  /// Crée une sous-tâche depuis JSON
  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);

  /// Crée une nouvelle sous-tâche avec des valeurs par défaut
  factory Subtask.create({
    required String text,
    bool done = false,
  }) {
    final now = DateTime.now();
    return Subtask(
      id: _generateId(),
      text: text,
      done: done,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Génère un ID unique pour la sous-tâche
  static String _generateId() {
    return 'subtask_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  /// Marque la sous-tâche comme terminée
  Subtask markAsCompleted() {
    return copyWith(
      done: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Marque la sous-tâche comme non terminée
  Subtask markAsIncomplete() {
    return copyWith(
      done: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Bascule l'état de la sous-tâche
  Subtask toggle() {
    return copyWith(
      done: !done,
      updatedAt: DateTime.now(),
    );
  }

  /// Met à jour le texte de la sous-tâche
  Subtask updateText(String newText) {
    return copyWith(
      text: newText,
      updatedAt: DateTime.now(),
    );
  }

  /// Compare deux sous-tâches pour le tri
  /// Les sous-tâches non terminées apparaissent en premier
  int compareTo(Subtask other) {
    // D'abord par statut (non terminées en premier)
    if (done != other.done) {
      return done ? 1 : -1;
    }
    
    // Ensuite par ordre de création
    return createdAt.compareTo(other.createdAt);
  }

  /// Indique si la sous-tâche est vide (texte vide ou seulement des espaces)
  bool get isEmpty => text.trim().isEmpty;

  /// Obtient le texte formaté (supprime les espaces en début/fin)
  String get formattedText => text.trim();
}

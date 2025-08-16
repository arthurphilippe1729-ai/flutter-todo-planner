import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/task.dart';
import '../../models/subtask.dart';
import '../../models/category.dart';
import '../adapters/task_adapter.dart';
import '../adapters/subtask_adapter.dart';
import '../adapters/category_adapter.dart';

/// Service de gestion de la base de données Hive
class HiveDatabase {
  static const String _tasksBoxName = 'tasks';
  static const String _categoriesBoxName = 'categories';
  static const String _settingsBoxName = 'settings';
  
  static Box<Task>? _tasksBox;
  static Box<Category>? _categoriesBox;
  static Box<dynamic>? _settingsBox;

  /// Initialise la base de données Hive
  static Future<void> initialize() async {
    try {
      // Initialisation de Hive avec le répertoire de l'application
      if (!kIsWeb) {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocumentDir.path);
      }

      // Enregistrement des adapters
      _registerAdapters();

      // Ouverture des boxes
      await _openBoxes();

      // Initialisation des données par défaut
      await _initializeDefaultData();

      debugPrint('✅ Base de données Hive initialisée avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation de Hive: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Enregistre les adapters Hive
  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SubtaskAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CategoryAdapter());
    }
  }

  /// Ouvre les boxes Hive
  static Future<void> _openBoxes() async {
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _categoriesBox = await Hive.openBox<Category>(_categoriesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Initialise les données par défaut si nécessaire
  static Future<void> _initializeDefaultData() async {
    // Créer les catégories par défaut si aucune n'existe
    if (_categoriesBox!.isEmpty) {
      final defaultCategories = Category.createDefaultCategories();
      for (final category in defaultCategories) {
        await _categoriesBox!.put(category.id, category);
      }
      debugPrint('✅ Catégories par défaut créées');
    }

    // Créer des tâches d'exemple si aucune n'existe
    if (_tasksBox!.isEmpty) {
      await _createSampleTasks();
      debugPrint('✅ Tâches d\'exemple créées');
    }

    // Initialiser les paramètres par défaut
    await _initializeDefaultSettings();
  }

  /// Crée des tâches d'exemple
  static Future<void> _createSampleTasks() async {
    final now = DateTime.now();
    final categories = _categoriesBox!.values.toList();
    
    // Trouve les catégories par défaut
    final workCategory = categories.firstWhere(
      (c) => c.name == 'Travail',
      orElse: () => categories.first,
    );
    final healthCategory = categories.firstWhere(
      (c) => c.name == 'Santé',
      orElse: () => categories.first,
    );
    final personalCategory = categories.firstWhere(
      (c) => c.name == 'Perso',
      orElse: () => categories.first,
    );

    final sampleTasks = [
      // 1. Réunion sprint (Travail) aujourd'hui 09:30-10:15
      Task.create(
        title: 'Réunion sprint',
        description: 'Point hebdomadaire avec l\'équipe de développement',
        startAt: DateTime(now.year, now.month, now.day, 9, 30),
        endAt: DateTime(now.year, now.month, now.day, 10, 15),
        priority: TaskPriority.high,
        categoryId: workCategory.id,
        reminders: [10], // 10 minutes avant
        tags: ['réunion', 'équipe'],
      ),

      // 2. Sport (Santé) 18:00-19:00 lun/mer/ven (récurrent)
      Task.create(
        title: 'Sport',
        description: 'Séance de fitness à la salle de sport',
        startAt: DateTime(now.year, now.month, now.day, 18, 0),
        endAt: DateTime(now.year, now.month, now.day, 19, 0),
        priority: TaskPriority.medium,
        categoryId: healthCategory.id,
        reminders: [60, 10], // 60 et 10 minutes avant
        tags: ['sport', 'santé'],
      ).copyWith(
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
      ),

      // 3. Courses (Perso) samedi 11:00-12:00 avec checklist
      Task.create(
        title: 'Courses',
        description: 'Faire les courses hebdomadaires au supermarché',
        startAt: DateTime(now.year, now.month, now.day + (6 - now.weekday), 11, 0),
        endAt: DateTime(now.year, now.month, now.day + (6 - now.weekday), 12, 0),
        priority: TaskPriority.medium,
        categoryId: personalCategory.id,
        reminders: [30],
        tags: ['courses', 'maison'],
      ).copyWith(
        checklist: [
          Subtask.create(text: 'Lait'),
          Subtask.create(text: 'Œufs'),
          Subtask.create(text: 'Café'),
          Subtask.create(text: 'Pain'),
          Subtask.create(text: 'Légumes'),
        ],
      ),

      // 4. Lecture (Perso) 22:00-22:30 tous les jours (récurrent)
      Task.create(
        title: 'Lecture',
        description: 'Lire 30 minutes avant de dormir',
        startAt: DateTime(now.year, now.month, now.day, 22, 0),
        endAt: DateTime(now.year, now.month, now.day, 22, 30),
        priority: TaskPriority.low,
        categoryId: personalCategory.id,
        reminders: [5],
        tags: ['lecture', 'détente'],
      ).copyWith(
        recurrenceRule: 'FREQ=DAILY',
      ),

      // 5. Appel médecin (Santé) demain 14:00-14:30
      Task.create(
        title: 'Appel médecin',
        description: 'Prendre rendez-vous pour le contrôle annuel',
        startAt: DateTime(now.year, now.month, now.day + 1, 14, 0),
        endAt: DateTime(now.year, now.month, now.day + 1, 14, 30),
        priority: TaskPriority.high,
        categoryId: healthCategory.id,
        reminders: [60, 15],
        tags: ['médecin', 'santé'],
      ),

      // 6. Présentation projet (Travail) après-demain 15:00-16:00
      Task.create(
        title: 'Présentation projet',
        description: 'Présenter l\'avancement du projet aux clients',
        startAt: DateTime(now.year, now.month, now.day + 2, 15, 0),
        endAt: DateTime(now.year, now.month, now.day + 2, 16, 0),
        priority: TaskPriority.urgent,
        categoryId: workCategory.id,
        reminders: [120, 30, 5],
        tags: ['présentation', 'client'],
      ),
    ];

    // Sauvegarde des tâches d'exemple
    for (final task in sampleTasks) {
      await _tasksBox!.put(task.id, task);
    }
  }

  /// Initialise les paramètres par défaut
  static Future<void> _initializeDefaultSettings() async {
    final defaultSettings = {
      'theme_mode': 'system', // system, light, dark
      'first_day_of_week': 1, // 1 = lundi, 7 = dimanche
      'snap_interval': 15, // 5 ou 15 minutes
      'default_task_duration': 60, // en minutes
      'notifications_enabled': true,
      'sound_enabled': true,
      'vibration_enabled': true,
      'app_version': '1.0.0',
      'first_launch': true,
      'onboarding_completed': false,
    };

    for (final entry in defaultSettings.entries) {
      if (!_settingsBox!.containsKey(entry.key)) {
        await _settingsBox!.put(entry.key, entry.value);
      }
    }
  }

  /// Getters pour les boxes
  static Box<Task> get tasksBox {
    if (_tasksBox == null || !_tasksBox!.isOpen) {
      throw Exception('Tasks box n\'est pas initialisée');
    }
    return _tasksBox!;
  }

  static Box<Category> get categoriesBox {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw Exception('Categories box n\'est pas initialisée');
    }
    return _categoriesBox!;
  }

  static Box<dynamic> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box n\'est pas initialisée');
    }
    return _settingsBox!;
  }

  /// Ferme toutes les boxes
  static Future<void> close() async {
    await _tasksBox?.close();
    await _categoriesBox?.close();
    await _settingsBox?.close();
    debugPrint('✅ Toutes les boxes Hive fermées');
  }

  /// Supprime toutes les données (pour les tests ou reset)
  static Future<void> clearAll() async {
    await _tasksBox?.clear();
    await _categoriesBox?.clear();
    await _settingsBox?.clear();
    debugPrint('⚠️ Toutes les données supprimées');
  }

  /// Exporte toutes les données en JSON
  static Map<String, dynamic> exportData() {
    final tasks = _tasksBox?.values.map((task) => task.toJson()).toList() ?? [];
    final categories = _categoriesBox?.values.map((category) => category.toJson()).toList() ?? [];
    final settings = Map<String, dynamic>.from(_settingsBox?.toMap() ?? {});

    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'tasks': tasks,
      'categories': categories,
      'settings': settings,
    };
  }

  /// Importe des données depuis JSON
  static Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Vérification de la version
      final version = data['version'] as String?;
      if (version == null) {
        throw Exception('Version manquante dans les données d\'import');
      }

      // Import des catégories
      final categoriesData = data['categories'] as List<dynamic>?;
      if (categoriesData != null) {
        await _categoriesBox?.clear();
        for (final categoryJson in categoriesData) {
          final category = Category.fromJson(categoryJson as Map<String, dynamic>);
          await _categoriesBox?.put(category.id, category);
        }
      }

      // Import des tâches
      final tasksData = data['tasks'] as List<dynamic>?;
      if (tasksData != null) {
        await _tasksBox?.clear();
        for (final taskJson in tasksData) {
          final task = Task.fromJson(taskJson as Map<String, dynamic>);
          await _tasksBox?.put(task.id, task);
        }
      }

      // Import des paramètres
      final settingsData = data['settings'] as Map<String, dynamic>?;
      if (settingsData != null) {
        for (final entry in settingsData.entries) {
          await _settingsBox?.put(entry.key, entry.value);
        }
      }

      debugPrint('✅ Données importées avec succès');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'import: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtient les statistiques de la base de données
  static Map<String, dynamic> getStats() {
    return {
      'tasks_count': _tasksBox?.length ?? 0,
      'categories_count': _categoriesBox?.length ?? 0,
      'settings_count': _settingsBox?.length ?? 0,
      'database_size_mb': _calculateDatabaseSize(),
    };
  }

  /// Calcule la taille approximative de la base de données
  static double _calculateDatabaseSize() {
    // Estimation approximative basée sur le nombre d'entrées
    final tasksCount = _tasksBox?.length ?? 0;
    final categoriesCount = _categoriesBox?.length ?? 0;
    final settingsCount = _settingsBox?.length ?? 0;
    
    // Estimation: ~1KB par tâche, ~0.5KB par catégorie, ~0.1KB par paramètre
    final estimatedBytes = (tasksCount * 1024) + (categoriesCount * 512) + (settingsCount * 100);
    return estimatedBytes / (1024 * 1024); // Conversion en MB
  }
}

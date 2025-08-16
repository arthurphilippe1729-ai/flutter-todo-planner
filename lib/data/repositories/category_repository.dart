import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../models/category.dart';
import '../database/hive_database.dart';

/// Repository pour la gestion des catégories
class CategoryRepository {
  late final Box<Category> _box;

  CategoryRepository() {
    _box = HiveDatabase.categoriesBox;
  }

  /// Obtient toutes les catégories
  List<Category> getAllCategories() {
    try {
      return _box.values.toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  /// Obtient toutes les catégories actives (non archivées)
  List<Category> getActiveCategories() {
    try {
      return _box.values.where((category) => category.isActive).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des catégories actives: $e');
      return [];
    }
  }

  /// Obtient toutes les catégories archivées
  List<Category> getArchivedCategories() {
    try {
      return _box.values.where((category) => category.isArchived).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des catégories archivées: $e');
      return [];
    }
  }

  /// Obtient une catégorie par son ID
  Category? getCategoryById(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la catégorie $id: $e');
      return null;
    }
  }

  /// Obtient une catégorie par son nom
  Category? getCategoryByName(String name) {
    try {
      return _box.values.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null; // Pas d'erreur si non trouvée
    }
  }

  /// Recherche des catégories par texte
  List<Category> searchCategories(String query) {
    try {
      if (query.isEmpty) return getAllCategories();
      
      final lowerQuery = query.toLowerCase();
      return _box.values.where((category) {
        return category.name.toLowerCase().contains(lowerQuery) ||
               (category.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de catégories avec "$query": $e');
      return [];
    }
  }

  /// Trie les catégories
  List<Category> sortCategories(List<Category> categories, CategorySortType sortType) {
    try {
      final sortedCategories = List<Category>.from(categories);
      
      switch (sortType) {
        case CategorySortType.name:
          sortedCategories.sort((a, b) => a.compareByName(b));
          break;
        case CategorySortType.createdAt:
          sortedCategories.sort((a, b) => a.compareByCreationDate(b));
          break;
        case CategorySortType.updatedAt:
          sortedCategories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case CategorySortType.color:
          sortedCategories.sort((a, b) => a.colorHex.compareTo(b.colorHex));
          break;
      }
      
      return sortedCategories;
    } catch (e) {
      debugPrint('❌ Erreur lors du tri des catégories: $e');
      return categories;
    }
  }

  /// Sauvegarde une catégorie
  Future<bool> saveCategory(Category category) async {
    try {
      await _box.put(category.id, category);
      debugPrint('✅ Catégorie "${category.name}" sauvegardée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde de la catégorie "${category.name}": $e');
      return false;
    }
  }

  /// Met à jour une catégorie
  Future<bool> updateCategory(Category category) async {
    try {
      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      await _box.put(updatedCategory.id, updatedCategory);
      debugPrint('✅ Catégorie "${category.name}" mise à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de la catégorie "${category.name}": $e');
      return false;
    }
  }

  /// Supprime une catégorie
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final category = _box.get(categoryId);
      await _box.delete(categoryId);
      debugPrint('✅ Catégorie "${category?.name ?? categoryId}" supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la catégorie $categoryId: $e');
      return false;
    }
  }

  /// Archive une catégorie
  Future<bool> archiveCategory(String categoryId) async {
    try {
      final category = _box.get(categoryId);
      if (category != null) {
        final archivedCategory = category.archive();
        await _box.put(categoryId, archivedCategory);
        debugPrint('✅ Catégorie "${category.name}" archivée');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'archivage de la catégorie $categoryId: $e');
      return false;
    }
  }

  /// Désarchive une catégorie
  Future<bool> unarchiveCategory(String categoryId) async {
    try {
      final category = _box.get(categoryId);
      if (category != null) {
        final unarchivedCategory = category.unarchive();
        await _box.put(categoryId, unarchivedCategory);
        debugPrint('✅ Catégorie "${category.name}" désarchivée');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors du désarchivage de la catégorie $categoryId: $e');
      return false;
    }
  }

  /// Change la couleur d'une catégorie
  Future<bool> changeCategoryColor(String categoryId, String newColorHex) async {
    try {
      final category = _box.get(categoryId);
      if (category != null) {
        final updatedCategory = category.changeColor(newColorHex);
        await _box.put(categoryId, updatedCategory);
        debugPrint('✅ Couleur de la catégorie "${category.name}" changée');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors du changement de couleur de la catégorie $categoryId: $e');
      return false;
    }
  }

  /// Renomme une catégorie
  Future<bool> renameCategory(String categoryId, String newName) async {
    try {
      // Vérifier si le nom n'est pas déjà utilisé
      if (isCategoryNameExists(newName, excludeId: categoryId)) {
        debugPrint('❌ Le nom de catégorie "$newName" existe déjà');
        return false;
      }

      final category = _box.get(categoryId);
      if (category != null) {
        final renamedCategory = category.rename(newName);
        await _box.put(categoryId, renamedCategory);
        debugPrint('✅ Catégorie renommée en "$newName"');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors du renommage de la catégorie $categoryId: $e');
      return false;
    }
  }

  /// Vérifie si un nom de catégorie existe déjà
  bool isCategoryNameExists(String name, {String? excludeId}) {
    try {
      return _box.values.any((category) {
        if (excludeId != null && category.id == excludeId) {
          return false; // Exclure la catégorie spécifiée
        }
        return category.name.toLowerCase() == name.toLowerCase();
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du nom de catégorie: $e');
      return false;
    }
  }

  /// Crée une nouvelle catégorie avec un nom unique
  Future<Category?> createCategory({
    required String name,
    String? colorHex,
    String? description,
  }) async {
    try {
      // Vérifier si le nom n'existe pas déjà
      if (isCategoryNameExists(name)) {
        debugPrint('❌ Le nom de catégorie "$name" existe déjà');
        return null;
      }

      final category = Category.create(
        name: name,
        colorHex: colorHex,
        description: description,
      );

      final success = await saveCategory(category);
      return success ? category : null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la catégorie "$name": $e');
      return null;
    }
  }

  /// Obtient les statistiques des catégories
  CategoryStats getCategoryStats() {
    try {
      final allCategories = getAllCategories();
      final activeCategories = getActiveCategories();
      final archivedCategories = getArchivedCategories();
      
      return CategoryStats(
        totalCategories: allCategories.length,
        activeCategories: activeCategories.length,
        archivedCategories: archivedCategories.length,
        defaultCategories: allCategories.where((cat) => cat.isDefault).length,
        customCategories: allCategories.where((cat) => !cat.isDefault).length,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul des statistiques des catégories: $e');
      return CategoryStats.empty();
    }
  }

  /// Réinitialise les catégories par défaut
  Future<bool> resetToDefaultCategories() async {
    try {
      // Supprimer toutes les catégories existantes
      await _box.clear();
      
      // Recréer les catégories par défaut
      final defaultCategories = Category.createDefaultCategories();
      for (final category in defaultCategories) {
        await _box.put(category.id, category);
      }
      
      debugPrint('✅ Catégories réinitialisées aux valeurs par défaut');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la réinitialisation des catégories: $e');
      return false;
    }
  }

  /// Obtient la catégorie par défaut pour les nouvelles tâches
  Category? getDefaultCategory() {
    try {
      final activeCategories = getActiveCategories();
      if (activeCategories.isEmpty) return null;
      
      // Chercher la catégorie "Perso" en premier
      final personalCategory = activeCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == 'perso',
        orElse: () => activeCategories.first,
      );
      
      return personalCategory;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la catégorie par défaut: $e');
      return null;
    }
  }

  /// Écoute les changements dans la box
  Stream<BoxEvent> watchCategories() {
    return _box.watch();
  }

  /// Exporte toutes les catégories en JSON
  List<Map<String, dynamic>> exportCategories() {
    try {
      return _box.values.map((category) => category.toJson()).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'export des catégories: $e');
      return [];
    }
  }

  /// Importe des catégories depuis JSON
  Future<bool> importCategories(List<Map<String, dynamic>> categoriesJson, {bool clearExisting = false}) async {
    try {
      if (clearExisting) {
        await _box.clear();
      }

      for (final categoryJson in categoriesJson) {
        final category = Category.fromJson(categoryJson);
        await _box.put(category.id, category);
      }

      debugPrint('✅ ${categoriesJson.length} catégories importées');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'import des catégories: $e');
      return false;
    }
  }
}

/// Énumération pour les types de tri des catégories
enum CategorySortType {
  name,
  createdAt,
  updatedAt,
  color,
}

/// Classe pour les statistiques des catégories
class CategoryStats {
  final int totalCategories;
  final int activeCategories;
  final int archivedCategories;
  final int defaultCategories;
  final int customCategories;

  const CategoryStats({
    required this.totalCategories,
    required this.activeCategories,
    required this.archivedCategories,
    required this.defaultCategories,
    required this.customCategories,
  });

  factory CategoryStats.empty() {
    return const CategoryStats(
      totalCategories: 0,
      activeCategories: 0,
      archivedCategories: 0,
      defaultCategories: 0,
      customCategories: 0,
    );
  }

  /// Pourcentage de catégories actives
  double get activeRate {
    if (totalCategories == 0) return 0.0;
    return activeCategories / totalCategories;
  }

  /// Pourcentage de catégories personnalisées
  double get customRate {
    if (totalCategories == 0) return 0.0;
    return customCategories / totalCategories;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../data/repositories/category_repository.dart';

part 'category_provider.g.dart';

/// Provider pour le repository des catégories
@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepository();
}

/// Provider pour toutes les catégories
@riverpod
class Categories extends _$Categories {
  @override
  List<Category> build() {
    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getAllCategories();
  }

  /// Recharge les catégories depuis la base de données
  void refresh() {
    final repository = ref.read(categoryRepositoryProvider);
    state = repository.getAllCategories();
  }

  /// Ajoute une nouvelle catégorie
  Future<Category?> addCategory({
    required String name,
    String? colorHex,
    String? description,
  }) async {
    final repository = ref.read(categoryRepositoryProvider);
    final category = await repository.createCategory(
      name: name,
      colorHex: colorHex,
      description: description,
    );
    
    if (category != null) {
      refresh();
    }
    
    return category;
  }

  /// Met à jour une catégorie existante
  Future<bool> updateCategory(Category category) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.updateCategory(category);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Supprime une catégorie
  Future<bool> deleteCategory(String categoryId) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.deleteCategory(categoryId);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Archive une catégorie
  Future<bool> archiveCategory(String categoryId) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.archiveCategory(categoryId);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Désarchive une catégorie
  Future<bool> unarchiveCategory(String categoryId) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.unarchiveCategory(categoryId);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Change la couleur d'une catégorie
  Future<bool> changeCategoryColor(String categoryId, String newColorHex) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.changeCategoryColor(categoryId, newColorHex);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Renomme une catégorie
  Future<bool> renameCategory(String categoryId, String newName) async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.renameCategory(categoryId, newName);
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Réinitialise aux catégories par défaut
  Future<bool> resetToDefaults() async {
    final repository = ref.read(categoryRepositoryProvider);
    final success = await repository.resetToDefaultCategories();
    
    if (success) {
      refresh();
    }
    
    return success;
  }

  /// Vérifie si un nom de catégorie existe
  bool isCategoryNameExists(String name, {String? excludeId}) {
    final repository = ref.read(categoryRepositoryProvider);
    return repository.isCategoryNameExists(name, excludeId: excludeId);
  }
}

/// Provider pour les catégories actives (non archivées)
@riverpod
List<Category> activeCategories(ActiveCategoriesRef ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getActiveCategories();
}

/// Provider pour les catégories archivées
@riverpod
List<Category> archivedCategories(ArchivedCategoriesRef ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getArchivedCategories();
}

/// Provider pour une catégorie spécifique par ID
@riverpod
Category? categoryById(CategoryByIdRef ref, String categoryId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
}

/// Provider pour une catégorie par nom
@riverpod
Category? categoryByName(CategoryByNameRef ref, String name) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryByName(name);
}

/// Provider pour la catégorie par défaut
@riverpod
Category? defaultCategory(DefaultCategoryRef ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getDefaultCategory();
}

/// Provider pour la recherche de catégories
@riverpod
class CategorySearch extends _$CategorySearch {
  @override
  List<Category> build() {
    return [];
  }

  /// Recherche des catégories par query
  void search(String query) {
    final repository = ref.read(categoryRepositoryProvider);
    state = repository.searchCategories(query);
  }

  /// Efface la recherche
  void clear() {
    state = [];
  }
}

/// Provider pour le tri des catégories
@riverpod
class CategorySort extends _$CategorySort {
  @override
  CategorySortState build() {
    return const CategorySortState();
  }

  /// Change le type de tri
  void setSortType(CategorySortType sortType) {
    state = state.copyWith(sortType: sortType);
  }

  /// Bascule l'ordre de tri
  void toggleSortOrder() {
    state = state.copyWith(ascending: !state.ascending);
  }

  /// Applique le tri aux catégories
  List<Category> sortCategories(List<Category> categories) {
    final repository = ref.read(categoryRepositoryProvider);
    final sortedCategories = repository.sortCategories(categories, state.sortType);
    
    return state.ascending ? sortedCategories : sortedCategories.reversed.toList();
  }
}

/// Provider pour les catégories triées
@riverpod
List<Category> sortedCategories(SortedCategoriesRef ref) {
  final allCategories = ref.watch(categoriesProvider);
  final sortNotifier = ref.read(categorySortProvider.notifier);
  
  return sortNotifier.sortCategories(allCategories);
}

/// Provider pour les catégories actives triées
@riverpod
List<Category> sortedActiveCategories(SortedActiveCategoriesRef ref) {
  final activeCategories = ref.watch(activeCategoriesProvider);
  final sortNotifier = ref.read(categorySortProvider.notifier);
  
  return sortNotifier.sortCategories(activeCategories);
}

/// Provider pour les statistiques des catégories
@riverpod
CategoryStats categoryStats(CategoryStatsRef ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryStats();
}

/// Provider pour l'export des catégories
@riverpod
List<Map<String, dynamic>> exportCategories(ExportCategoriesRef ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.exportCategories();
}

/// Provider pour la gestion des couleurs de catégories
@riverpod
class CategoryColors extends _$CategoryColors {
  @override
  List<String> build() {
    // Retourne les couleurs par défaut disponibles
    return [
      '#4CAF50', // Vert
      '#2196F3', // Bleu
      '#FF9800', // Orange
      '#9C27B0', // Violet
      '#E91E63', // Rose
      '#00BCD4', // Cyan
      '#FFEB3B', // Jaune
      '#795548', // Marron
      '#607D8B', // Bleu-gris
      '#FF5722', // Rouge-orange
      '#3F51B5', // Indigo
      '#009688', // Teal
      '#FFC107', // Ambre
      '#8BC34A', // Vert clair
      '#F44336', // Rouge
      '#673AB7', // Violet profond
    ];
  }

  /// Obtient une couleur disponible (non utilisée)
  String getAvailableColor() {
    final usedColors = ref.read(categoriesProvider)
        .map((category) => category.colorHex)
        .toSet();
    
    // Trouve la première couleur non utilisée
    for (final color in state) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }
    
    // Si toutes les couleurs sont utilisées, retourne la première
    return state.first;
  }

  /// Obtient une couleur aléatoire
  String getRandomColor() {
    final random = DateTime.now().millisecondsSinceEpoch % state.length;
    return state[random];
  }
}

/// Provider pour la validation des noms de catégories
@riverpod
class CategoryValidator extends _$CategoryValidator {
  @override
  CategoryValidationState build() {
    return const CategoryValidationState();
  }

  /// Valide un nom de catégorie
  void validateName(String name, {String? excludeId}) {
    final repository = ref.read(categoryRepositoryProvider);
    
    if (name.trim().isEmpty) {
      state = const CategoryValidationState(
        isValid: false,
        error: 'Le nom ne peut pas être vide',
      );
      return;
    }
    
    if (name.trim().length < 2) {
      state = const CategoryValidationState(
        isValid: false,
        error: 'Le nom doit contenir au moins 2 caractères',
      );
      return;
    }
    
    if (name.trim().length > 50) {
      state = const CategoryValidationState(
        isValid: false,
        error: 'Le nom ne peut pas dépasser 50 caractères',
      );
      return;
    }
    
    if (repository.isCategoryNameExists(name.trim(), excludeId: excludeId)) {
      state = const CategoryValidationState(
        isValid: false,
        error: 'Ce nom de catégorie existe déjà',
      );
      return;
    }
    
    state = const CategoryValidationState(isValid: true);
  }

  /// Efface la validation
  void clear() {
    state = const CategoryValidationState();
  }
}

/// État du tri des catégories
class CategorySortState {
  final CategorySortType sortType;
  final bool ascending;

  const CategorySortState({
    this.sortType = CategorySortType.name,
    this.ascending = true,
  });

  /// Copie avec de nouveaux paramètres
  CategorySortState copyWith({
    CategorySortType? sortType,
    bool? ascending,
  }) {
    return CategorySortState(
      sortType: sortType ?? this.sortType,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// État de validation des catégories
class CategoryValidationState {
  final bool isValid;
  final String? error;

  const CategoryValidationState({
    this.isValid = true,
    this.error,
  });
}

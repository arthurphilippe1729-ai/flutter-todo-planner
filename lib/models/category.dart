import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import '../theme/color_schemes.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Modèle pour une catégorie de tâches
@freezed
@HiveType(typeId: 4)
class Category with _$Category {
  const factory Category({
    /// Identifiant unique de la catégorie
    @HiveField(0) required String id,
    
    /// Nom de la catégorie
    @HiveField(1) required String name,
    
    /// Couleur de la catégorie en hexadécimal
    @HiveField(2) required String colorHex,
    
    /// Description optionnelle de la catégorie
    @HiveField(3) String? description,
    
    /// Indique si la catégorie est archivée
    @HiveField(4) @Default(false) bool isArchived,
    
    /// Date de création
    @HiveField(5) required DateTime createdAt,
    
    /// Date de dernière modification
    @HiveField(6) required DateTime updatedAt,
  }) = _Category;

  const Category._();

  /// Crée une catégorie depuis JSON
  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  /// Crée une nouvelle catégorie avec des valeurs par défaut
  factory Category.create({
    required String name,
    String? colorHex,
    String? description,
  }) {
    final now = DateTime.now();
    return Category(
      id: _generateId(),
      name: name,
      colorHex: colorHex ?? CategoryColors.colorToHex(CategoryColors.defaultColors.first),
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Génère un ID unique pour la catégorie
  static String _generateId() {
    return 'category_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  /// Obtient la couleur Flutter depuis le hex
  Color get color => CategoryColors.hexToColor(colorHex);

  /// Obtient une version plus claire de la couleur pour les arrière-plans
  Color get lightColor => color.withOpacity(0.1);

  /// Obtient une version plus foncée de la couleur pour les bordures
  Color get darkColor => Color.lerp(color, const Color(0xFF000000), 0.2) ?? color;

  /// Indique si la catégorie est active (non archivée)
  bool get isActive => !isArchived;

  /// Met à jour la catégorie
  Category update({
    String? name,
    String? colorHex,
    String? description,
    bool? isArchived,
  }) {
    return copyWith(
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      updatedAt: DateTime.now(),
    );
  }

  /// Archive la catégorie
  Category archive() {
    return copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Désarchive la catégorie
  Category unarchive() {
    return copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Change la couleur de la catégorie
  Category changeColor(String newColorHex) {
    return copyWith(
      colorHex: newColorHex,
      updatedAt: DateTime.now(),
    );
  }

  /// Renomme la catégorie
  Category rename(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  /// Compare deux catégories pour le tri alphabétique
  int compareByName(Category other) {
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }

  /// Compare deux catégories pour le tri par date de création
  int compareByCreationDate(Category other) {
    return createdAt.compareTo(other.createdAt);
  }

  /// Indique si le nom de la catégorie est valide
  bool get hasValidName => name.trim().isNotEmpty;

  /// Obtient le nom formaté (supprime les espaces en début/fin)
  String get formattedName => name.trim();

  /// Crée les catégories par défaut
  static List<Category> createDefaultCategories() {
    final now = DateTime.now();
    
    return [
      Category(
        id: 'default_personal',
        name: 'Perso',
        colorHex: '#4CAF50', // Vert
        description: 'Tâches personnelles et vie privée',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'default_work',
        name: 'Travail',
        colorHex: '#2196F3', // Bleu
        description: 'Tâches professionnelles et projets',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'default_health',
        name: 'Santé',
        colorHex: '#FF9800', // Orange
        description: 'Sport, médecin, bien-être',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'default_leisure',
        name: 'Loisirs',
        colorHex: '#9C27B0', // Violet
        description: 'Hobbies, sorties, divertissement',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'default_social',
        name: 'Social',
        colorHex: '#E91E63', // Rose
        description: 'Famille, amis, événements sociaux',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Obtient une catégorie par défaut selon le nom
  static Category? getDefaultByName(String name) {
    final defaultCategories = createDefaultCategories();
    try {
      return defaultCategories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si c'est une catégorie par défaut
  bool get isDefault => id.startsWith('default_');

  /// Obtient l'icône suggérée selon le nom de la catégorie
  String get suggestedIcon {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('perso') || lowerName.contains('personnel')) {
      return 'person';
    } else if (lowerName.contains('travail') || lowerName.contains('boulot') || lowerName.contains('job')) {
      return 'work';
    } else if (lowerName.contains('santé') || lowerName.contains('sport') || lowerName.contains('médecin')) {
      return 'health_and_safety';
    } else if (lowerName.contains('loisir') || lowerName.contains('hobby') || lowerName.contains('jeu')) {
      return 'sports_esports';
    } else if (lowerName.contains('social') || lowerName.contains('famille') || lowerName.contains('ami')) {
      return 'people';
    } else if (lowerName.contains('voyage') || lowerName.contains('vacances')) {
      return 'flight';
    } else if (lowerName.contains('maison') || lowerName.contains('ménage')) {
      return 'home';
    } else if (lowerName.contains('finance') || lowerName.contains('argent')) {
      return 'account_balance_wallet';
    } else if (lowerName.contains('éducation') || lowerName.contains('étude')) {
      return 'school';
    } else {
      return 'category';
    }
  }
}

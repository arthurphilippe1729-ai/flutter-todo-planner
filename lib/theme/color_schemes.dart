import 'package:flutter/material.dart';

/// Palette de couleurs Material 3 pour le thème clair
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  
  // Couleurs principales
  primary: Color(0xFF6750A4),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEADDFF),
  onPrimaryContainer: Color(0xFF21005D),
  
  // Couleurs secondaires
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF1D192B),
  
  // Couleurs tertiaires
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF31111D),
  
  // Couleurs d'erreur
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  
  // Couleurs de surface
  surface: Color(0xFFFFFBFE),
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerHighest: Color(0xFFE6E0E9),
  onSurfaceVariant: Color(0xFF49454F),
  
  // Couleurs d'outline
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  
  // Couleurs d'ombre et de scrim
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  
  // Couleur inverse
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFD0BCFF),
  
  // Nouvelles couleurs Material 3
  surfaceTint: Color(0xFF6750A4),
);

/// Palette de couleurs Material 3 pour le thème sombre
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  
  // Couleurs principales
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFEADDFF),
  
  // Couleurs secondaires
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  
  // Couleurs tertiaires
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  
  // Couleurs d'erreur
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  
  // Couleurs de surface
  surface: Color(0xFF100E13),
  onSurface: Color(0xFFE6E0E9),
  surfaceContainerHighest: Color(0xFF36343B),
  onSurfaceVariant: Color(0xFFCAC4D0),
  
  // Couleurs d'outline
  outline: Color(0xFF938F99),
  outlineVariant: Color(0xFF49454F),
  
  // Couleurs d'ombre et de scrim
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  
  // Couleur inverse
  inverseSurface: Color(0xFFE6E0E9),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6750A4),
  
  // Nouvelles couleurs Material 3
  surfaceTint: Color(0xFFD0BCFF),
);

/// Extensions pour les couleurs de surface Material 3
extension ColorSchemeExtension on ColorScheme {
  /// Surface container (niveau 0)
  Color get surfaceContainer => brightness == Brightness.light
      ? const Color(0xFFF3EDF7)
      : const Color(0xFF1D1B20);
  
  /// Surface container low (niveau 1)
  Color get surfaceContainerLow => brightness == Brightness.light
      ? const Color(0xFFF7F2FA)
      : const Color(0xFF1D1B20);
  
  /// Surface container high (niveau 2)
  Color get surfaceContainerHigh => brightness == Brightness.light
      ? const Color(0xFFECE6F0)
      : const Color(0xFF2B2930);
  
  /// Surface dim
  Color get surfaceDim => brightness == Brightness.light
      ? const Color(0xFFDDD8E1)
      : const Color(0xFF141218);
  
  /// Surface bright
  Color get surfaceBright => brightness == Brightness.light
      ? const Color(0xFFFFFBFE)
      : const Color(0xFF3B383E);
}

/// Couleurs spécifiques pour les priorités des tâches
class TaskPriorityColors {
  static const Color low = Color(0xFF4CAF50);      // Vert
  static const Color medium = Color(0xFFFF9800);   // Orange
  static const Color high = Color(0xFFFF5722);     // Rouge-orange
  static const Color urgent = Color(0xFFD32F2F);   // Rouge
  
  /// Obtient la couleur selon la priorité
  static Color getColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return low;
      case 'medium':
        return medium;
      case 'high':
        return high;
      case 'urgent':
        return urgent;
      default:
        return medium;
    }
  }
  
  /// Obtient la couleur avec opacité selon la priorité
  static Color getColorWithOpacity(String priority, double opacity) {
    return getColor(priority).withOpacity(opacity);
  }
}

/// Couleurs par défaut pour les catégories
class CategoryColors {
  static const List<Color> defaultColors = [
    Color(0xFF4CAF50), // Vert - Perso
    Color(0xFF2196F3), // Bleu - Travail
    Color(0xFFFF9800), // Orange - Santé
    Color(0xFF9C27B0), // Violet - Loisirs
    Color(0xFFE91E63), // Rose - Social
    Color(0xFF00BCD4), // Cyan - Voyage
    Color(0xFFFFEB3B), // Jaune - Finance
    Color(0xFF795548), // Marron - Maison
    Color(0xFF607D8B), // Bleu-gris - Éducation
    Color(0xFFFF5722), // Rouge-orange - Urgent
  ];
  
  /// Obtient une couleur par défaut selon l'index
  static Color getDefaultColor(int index) {
    return defaultColors[index % defaultColors.length];
  }
  
  /// Convertit une couleur en string hexadécimal
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// Convertit un string hexadécimal en couleur
  static Color hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

# Plan Détaillé - Application Flutter To-Do + Emploi du Temps + Semainier

## 🎯 Objectif
Créer une application Flutter complète combinant to-do list, emploi du temps avec drag & resize, et semainier, optimisée pour Samsung Galaxy S23 avec Material 3.

## 📋 Requirements Identifiés
- ✅ Aucune API key externe nécessaire
- ✅ Stockage local avec Hive
- ✅ Notifications locales avec flutter_local_notifications
- ✅ Permission POST_NOTIFICATIONS pour Android 13+
- ✅ Données d'exemple générées automatiquement au premier lancement

## 🏗️ Architecture Technique
### Framework & Versions
- Flutter 3.x, Dart 3.x
- Material 3 Design System
- Android: minSdk 24, targetSdk 34, compileSdk 34
- Localisation: fr-FR, format 24h, semaine lundi→dimanche

### Stack Technologique
- **Navigation**: go_router
- **State Management**: Riverpod 2
- **Base de données**: Hive (offline-first)
- **Sérialisation**: freezed + json_serializable
- **Notifications**: flutter_local_notifications + timezone
- **Internationalisation**: intl + flutter_localizations

## 📦 Modèles de Données
### Task
```dart
- id: String (UUID)
- title: String
- description: String?
- startAt: DateTime (TZ-aware)
- endAt: DateTime (TZ-aware)
- isAllDay: bool
- recurrenceRule: String? (RRULE)
- recurrenceEndsAt: DateTime?
- reminders: List<int> (minutes avant)
- status: TaskStatus (todo/in_progress/done)
- priority: Priority (low/medium/high/urgent)
- categoryId: String?
- tags: List<String>
- checklist: List<Subtask>
- createdAt: DateTime
- updatedAt: DateTime
```

### Subtask
```dart
- id: String
- text: String
- done: bool
```

### Category
```dart
- id: String
- name: String
- colorHex: String
```

## 🎨 Design System Material 3
### Palette de Couleurs
- Primary: #6750A4, onPrimary: #FFFFFF
- Secondary: #625B71, onSecondary: #FFFFFF
- Tertiary: #7D5260, onTertiary: #FFFFFF
- Surface: #FFFBFE, onSurface: #1C1B1F
- Error: #B3261E, onError: #FFFFFF

### Spacing & Layout
- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40 dp
- Border radius: 4dp (petits), 8dp (moyens), 12dp (containers), 28dp (FAB)
- Viewport cible: ~360×780 dp (Galaxy S23)

## 🖥️ Écrans à Implémenter
1. **Onboarding** - Permissions et configuration initiale
2. **Accueil** - BottomNavigationBar avec 4 onglets
3. **Aujourd'hui** - Timeline 24h + to-dos du jour
4. **Semaine** - Grille 7 colonnes avec indicateurs de progression
5. **Tâches** - Liste complète avec recherche/filtres/tri
6. **Détail Tâche** - Vue complète avec checklist et rappels
7. **Éditeur Tâche** - Formulaire complet de création/édition
8. **Réglages** - Configuration app et export/import

## 🧰 Fonctionnalités Clés
### To-Do List
- CRUD complet (tâches, sous-tâches, catégories, tags)
- Recherche plein texte + filtres multiples
- Tri par date, priorité, alphabétique

### Emploi du Temps
- Timeline 0-24h avec blocs visuels
- Création rapide par tap (30 min par défaut)
- Drag & drop + redimensionnement
- Détection de chevauchements avec alerte

### Semainier
- Vue 7 colonnes (lun→dim)
- Scroll horizontal par swipe
- Compteurs de progression par jour
- Mini-calendrier de navigation

### Notifications & Récurrence
- Rappels multiples par tâche
- Support RRULE simple (quotidien/hebdo/mensuel/annuel)
- Gestion des fuseaux horaires et DST
- Snooze depuis notifications

## 📁 Structure des Fichiers
```
flutter_todo_app/
├── pubspec.yaml
├── analysis_options.yaml
├── android/
│   ├── app/build.gradle.kts
│   ├── build.gradle.kts
│   └── gradle.properties
├── lib/
│   ├── main.dart
│   ├── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── color_schemes.dart
│   ├── models/
│   │   ├── task.dart
│   │   ├── subtask.dart
│   │   └── category.dart
│   ├── data/
│   │   ├── adapters/
│   │   ├── repositories/
│   │   └── database/
│   ├── services/
│   │   ├── notification_service.dart
│   │   ├── recurrence_service.dart
│   │   └── timezone_service.dart
│   ├── presentation/
│   │   ├── pages/
│   │   └── widgets/
│   └── providers/
├── test/
└── README.md
```

## 🔧 Configuration Build Android
- Java 17 + Kotlin jvmTarget=17
- AGP 8.x, compileSdk 34, minSdk 24
- NDK version: 27.0.12077973
- Minify/Shrink désactivés pour release

## 🌱 Données d'Exemple (Seed)
### Catégories
- "Perso" (#4CAF50)
- "Travail" (#2196F3)
- "Santé" (#FF9800)

### Tâches Exemples
1. "Réunion sprint" (Travail) 09:30–10:15 aujourd'hui
2. "Sport" (Santé) 18:00–19:00 lun/mer/ven (récurrent)
3. "Courses" (Perso) samedi 11:00–12:00 avec checklist
4. "Lecture" (Perso) 22:00–22:30 quotidien (récurrent)

## 🧪 Tests à Implémenter
### Tests Unitaires
- Règles de récurrence RRULE
- Repositories et services
- Logique métier des modèles

### Tests Widgets
- Éditeur de tâches
- Timeline avec drag & drop
- Grille semainier
- Navigation et routing

## 📸 Livrables Finaux
1. Code source complet et compilable
2. Configuration Android prête pour build APK
3. Tests unitaires et widgets
4. README avec instructions
5. Captures d'écran (clair/sombre)
6. Données d'exemple pré-chargées

## ✅ Critères d'Acceptation
- [x] Création tâche 14:00–15:30 → visible Jour et Semaine
- [x] Drag bloc 30 min → snap 15 min
- [x] Récurrence "Tous les lundis" → visible chaque lundi
- [x] Notifications respectent DST
- [x] Semaine commence lundi + compteurs progression
- [x] Export/Import JSON fidèle

## 🚀 Étapes d'Implémentation
1. **Setup projet** - pubspec.yaml, configuration Android
2. **Architecture** - routing, providers, theme
3. **Modèles** - Task, Category, Subtask avec freezed
4. **Services** - notifications, récurrence, timezone
5. **Data layer** - Hive adapters, repositories
6. **UI Components** - widgets réutilisables
7. **Pages** - écrans principaux
8. **Tests** - unitaires et widgets
9. **Seed data** - données d'exemple
10. **Polish** - animations, accessibilité, optimisations

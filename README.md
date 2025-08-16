# Todo & Planning - Application Flutter

Une application Flutter complète de gestion de tâches et de planning, optimisée pour Samsung Galaxy S23 avec Material 3.

## 🚀 Fonctionnalités

### ✅ To-Do List
- Création, modification et suppression de tâches
- Système de priorités (Faible, Moyenne, Élevée, Urgente)
- Catégories personnalisables avec couleurs
- Tags pour organiser les tâches
- Checklist avec sous-tâches
- Recherche et filtres avancés

### 📅 Emploi du Temps
- Vue timeline 24h avec blocs visuels
- Création rapide par tap sur créneau
- Drag & drop et redimensionnement des tâches
- Détection de chevauchements avec alerte
- Snap configurable (5 ou 15 minutes)

### 🗓️ Semainier
- Vue 7 colonnes (Lundi → Dimanche)
- Navigation par swipe horizontal
- Indicateurs de progression par jour
- Compteur de tâches terminées/totales

### 🔔 Notifications & Rappels
- Rappels multiples par tâche
- Support Android 13+ (POST_NOTIFICATIONS)
- Snooze depuis les notifications
- Gestion des fuseaux horaires et DST

### 🔄 Récurrence
- Support RRULE simple
- Quotidien, hebdomadaire, mensuel, annuel
- Jours de semaine spécifiques
- Édition d'occurrences individuelles

### 🎨 Interface Material 3
- Design adapté Galaxy S23 (19.5:9)
- Dynamic Color (Material You)
- Thèmes clair/sombre
- Accessibilité (TalkBack, contrastes WCAG AA)
- Animations fluides et micro-interactions

## 🏗️ Architecture

### Framework & Versions
- **Flutter**: 3.x
- **Dart**: 3.x
- **Material**: 3
- **Android**: minSdk 24, targetSdk 34

### Stack Technique
- **Navigation**: go_router
- **State Management**: Riverpod 2
- **Base de données**: Hive (offline-first)
- **Sérialisation**: freezed + json_serializable
- **Notifications**: flutter_local_notifications + timezone
- **Internationalisation**: intl (fr-FR)

### Structure du Projet
```
lib/
├── main.dart                 # Point d'entrée
├── app_router.dart          # Configuration navigation
├── theme/                   # Thèmes Material 3
├── models/                  # Modèles de données (freezed)
├── data/                    # Couche données
│   ├── adapters/           # Adapters Hive
│   ├── repositories/       # Repositories
│   └── database/           # Configuration Hive
├── services/               # Services métier
│   ├── notification_service.dart
│   ├── timezone_service.dart
│   └── recurrence_service.dart
├── providers/              # Providers Riverpod
├── presentation/           # Interface utilisateur
│   ├── pages/             # Pages principales
│   └── widgets/           # Widgets réutilisables
└── utils/                 # Utilitaires
```

## 🚀 Installation et Lancement

### Prérequis
- Flutter SDK 3.16.0+
- Dart SDK 3.2.0+
- Android Studio avec Android SDK
- NDK version 27.0.12077973

### Installation
```bash
# Cloner le projet
git clone <repository-url>
cd flutter_todo_app

# Installer les dépendances
flutter pub get

# Générer les fichiers de code
flutter packages pub run build_runner build

# Lancer l'application
flutter run
```

### Build Android
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

## 🧪 Tests

### Tests Unitaires
```bash
flutter test
```

### Tests d'Intégration
```bash
flutter test integration_test/
```

### Couverture de Tests
- Modèles de données et logique métier
- Services (notifications, récurrence, timezone)
- Repositories et providers
- Widgets critiques

## 📱 Configuration Android

### Permissions
- `POST_NOTIFICATIONS` (Android 13+) : Notifications locales
- `SCHEDULE_EXACT_ALARM` : Rappels précis
- `USE_EXACT_ALARM` : Alarmes exactes

### Configuration Gradle
- **Java**: 17
- **Kotlin**: jvmTarget 17
- **AGP**: 8.2.2
- **Compile SDK**: 34
- **Min SDK**: 24

## 🎯 Données d'Exemple

L'application génère automatiquement des données d'exemple au premier lancement :

### Catégories
- **Perso** (#4CAF50) - Tâches personnelles
- **Travail** (#2196F3) - Tâches professionnelles  
- **Santé** (#FF9800) - Sport, médecin, bien-être

### Tâches Exemples
1. **Réunion sprint** (Travail) - Aujourd'hui 09:30-10:15
2. **Sport** (Santé) - Lun/Mer/Ven 18:00-19:00 (récurrent)
3. **Courses** (Perso) - Samedi 11:00-12:00 avec checklist
4. **Lecture** (Perso) - 22:00-22:30 quotidien (récurrent)

## 🔧 Configuration

### Paramètres Disponibles
- **Thème** : Système, Clair, Sombre
- **Premier jour** : Lundi ou Dimanche
- **Snap** : 5 ou 15 minutes
- **Durée par défaut** : 30min, 1h, 2h
- **Notifications** : Son, vibration, rappels

### Export/Import
- Export JSON complet des données
- Sauvegarde locale automatique
- Restauration depuis fichier

## 🎨 Design System

### Couleurs Material 3
- **Primary**: #6750A4
- **Secondary**: #625B71  
- **Tertiary**: #7D5260
- **Surface**: #FFFBFE (clair) / #100E13 (sombre)
- **Error**: #B3261E

### Typographie
- **Display**: 57/45/36sp
- **Headline**: 32/28/24sp
- **Title**: 22/16/14sp
- **Body**: 16/14/12sp
- **Label**: 14/12/11sp

### Spacing Scale
4, 8, 12, 16, 20, 24, 32, 40 dp

## 🐛 Débogage

### Logs Utiles
```bash
# Logs Flutter
flutter logs

# Logs Android
adb logcat | grep flutter
```

### Problèmes Courants
1. **Notifications non reçues** : Vérifier permissions Android 13+
2. **Erreur de build** : Nettoyer avec `flutter clean`
3. **Base de données** : Supprimer et relancer pour reset

## 🤝 Contribution

### Standards de Code
- Lint strict avec `analysis_options.yaml`
- Commentaires en français
- Tests pour nouvelles fonctionnalités
- Respect Material 3 Guidelines

### Workflow
1. Fork du projet
2. Branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🙏 Remerciements

- **Flutter Team** pour le framework
- **Material Design** pour les guidelines
- **Riverpod** pour le state management
- **Hive** pour la base de données locale

---

**Version**: 1.0.0  
**Dernière mise à jour**: Décembre 2024  
**Compatibilité**: Android 7.0+ (API 24+)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/today_page.dart';
import 'presentation/pages/week_page.dart';
import 'presentation/pages/tasks_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/task_detail_page.dart';
import 'presentation/pages/task_editor_page.dart';

// Provider pour le routeur
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: true,
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Navigation principale avec BottomNavigationBar
      ShellRoute(
        builder: (context, state, child) {
          return HomePage(child: child);
        },
        routes: [
          // Aujourd'hui
          GoRoute(
            path: '/today',
            name: 'today',
            builder: (context, state) => const TodayPage(),
            routes: [
              // Détail d'une tâche depuis Aujourd'hui
              GoRoute(
                path: '/task/:taskId',
                name: 'today-task-detail',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return TaskDetailPage(taskId: taskId);
                },
              ),
              // Éditeur de tâche depuis Aujourd'hui
              GoRoute(
                path: '/edit/:taskId',
                name: 'today-task-edit',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];
                  final extra = state.extra as Map<String, dynamic>?;
                  return TaskEditorPage(
                    taskId: taskId,
                    initialDateTime: extra?['initialDateTime'] as DateTime?,
                  );
                },
              ),
              // Nouvelle tâche depuis Aujourd'hui
              GoRoute(
                path: '/new',
                name: 'today-task-new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return TaskEditorPage(
                    initialDateTime: extra?['initialDateTime'] as DateTime?,
                  );
                },
              ),
            ],
          ),
          
          // Semaine
          GoRoute(
            path: '/week',
            name: 'week',
            builder: (context, state) => const WeekPage(),
            routes: [
              // Détail d'une tâche depuis Semaine
              GoRoute(
                path: '/task/:taskId',
                name: 'week-task-detail',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return TaskDetailPage(taskId: taskId);
                },
              ),
              // Éditeur de tâche depuis Semaine
              GoRoute(
                path: '/edit/:taskId',
                name: 'week-task-edit',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];
                  final extra = state.extra as Map<String, dynamic>?;
                  return TaskEditorPage(
                    taskId: taskId,
                    initialDateTime: extra?['initialDateTime'] as DateTime?,
                  );
                },
              ),
              // Nouvelle tâche depuis Semaine
              GoRoute(
                path: '/new',
                name: 'week-task-new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return TaskEditorPage(
                    initialDateTime: extra?['initialDateTime'] as DateTime?,
                  );
                },
              ),
            ],
          ),
          
          // Tâches
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksPage(),
            routes: [
              // Détail d'une tâche depuis Tâches
              GoRoute(
                path: '/task/:taskId',
                name: 'tasks-task-detail',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return TaskDetailPage(taskId: taskId);
                },
              ),
              // Éditeur de tâche depuis Tâches
              GoRoute(
                path: '/edit/:taskId',
                name: 'tasks-task-edit',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];
                  return TaskEditorPage(taskId: taskId);
                },
              ),
              // Nouvelle tâche depuis Tâches
              GoRoute(
                path: '/new',
                name: 'tasks-task-new',
                builder: (context, state) => const TaskEditorPage(),
              ),
            ],
          ),
          
          // Réglages
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    
    // Gestion des erreurs de navigation
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'La page "${state.uri}" n\'existe pas.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/today'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
    
    // Redirection conditionnelle
    redirect: (context, state) {
      // Si on est sur la racine, rediriger vers /today
      if (state.uri.toString() == '/') {
        return '/today';
      }
      return null;
    },
  );
});

// Extensions utiles pour la navigation
extension GoRouterExtension on GoRouter {
  /// Navigue vers la page de détail d'une tâche depuis le contexte actuel
  void goToTaskDetail(String taskId) {
    final currentLocation = routerDelegate.currentConfiguration.uri.toString();
    
    if (currentLocation.startsWith('/today')) {
      go('/today/task/$taskId');
    } else if (currentLocation.startsWith('/week')) {
      go('/week/task/$taskId');
    } else if (currentLocation.startsWith('/tasks')) {
      go('/tasks/task/$taskId');
    } else {
      go('/today/task/$taskId');
    }
  }
  
  /// Navigue vers l'éditeur de tâche depuis le contexte actuel
  void goToTaskEditor({String? taskId, DateTime? initialDateTime}) {
    final currentLocation = routerDelegate.currentConfiguration.uri.toString();
    final extra = initialDateTime != null 
        ? {'initialDateTime': initialDateTime} 
        : null;
    
    if (taskId != null) {
      // Édition d'une tâche existante
      if (currentLocation.startsWith('/today')) {
        go('/today/edit/$taskId', extra: extra);
      } else if (currentLocation.startsWith('/week')) {
        go('/week/edit/$taskId', extra: extra);
      } else if (currentLocation.startsWith('/tasks')) {
        go('/tasks/edit/$taskId', extra: extra);
      } else {
        go('/today/edit/$taskId', extra: extra);
      }
    } else {
      // Création d'une nouvelle tâche
      if (currentLocation.startsWith('/today')) {
        go('/today/new', extra: extra);
      } else if (currentLocation.startsWith('/week')) {
        go('/week/new', extra: extra);
      } else if (currentLocation.startsWith('/tasks')) {
        go('/tasks/new', extra: extra);
      } else {
        go('/today/new', extra: extra);
      }
    }
  }
}

// Helper pour obtenir le routeur dans les widgets
extension BuildContextExtension on BuildContext {
  GoRouter get router => GoRouter.of(this);
}

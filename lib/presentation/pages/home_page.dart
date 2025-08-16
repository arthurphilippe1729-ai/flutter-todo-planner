import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';

/// Page d'accueil avec navigation principale
class HomePage extends ConsumerStatefulWidget {
  final Widget child;

  const HomePage({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Vérifier si l'onboarding est terminé
    final onboardingCompleted = ref.watch(isOnboardingCompletedProvider);
    
    if (!onboardingCompleted) {
      // Rediriger vers l'onboarding si pas encore terminé
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/onboarding');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Déterminer l'index sélectionné basé sur la route actuelle
    _updateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.secondaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Aujourd\'hui',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_week_outlined),
            selectedIcon: Icon(Icons.view_week_rounded),
            label: 'Semaine',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tâches',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Réglages',
          ),
        ],
      ),
      floatingActionButton: _shouldShowFAB() ? _buildFloatingActionButton(theme) : null,
    );
  }

  /// Met à jour l'index sélectionné basé sur la route actuelle
  void _updateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    if (location.startsWith('/today')) {
      _selectedIndex = 0;
    } else if (location.startsWith('/week')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/tasks')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/settings')) {
      _selectedIndex = 3;
    }
  }

  /// Gère la sélection d'une destination
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/today');
        break;
      case 1:
        context.go('/week');
        break;
      case 2:
        context.go('/tasks');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  /// Détermine si le FAB doit être affiché
  bool _shouldShowFAB() {
    // Afficher le FAB sur toutes les pages sauf les réglages
    return _selectedIndex != 3;
  }

  /// Construit le bouton d'action flottant
  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _onAddTask,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nouvelle tâche'),
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  /// Gère l'ajout d'une nouvelle tâche
  void _onAddTask() {
    final location = GoRouterState.of(context).uri.toString();
    
    // Naviguer vers l'éditeur de tâche selon la page actuelle
    if (location.startsWith('/today')) {
      context.go('/today/new');
    } else if (location.startsWith('/week')) {
      context.go('/week/new');
    } else if (location.startsWith('/tasks')) {
      context.go('/tasks/new');
    } else {
      // Par défaut, aller vers l'éditeur depuis aujourd'hui
      context.go('/today/new');
    }
  }
}

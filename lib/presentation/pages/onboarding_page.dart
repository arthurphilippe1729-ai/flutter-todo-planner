import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';

/// Page d'onboarding pour la première utilisation
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Bienvenue dans Todo & Planning',
      description: 'Organisez vos tâches, gérez votre emploi du temps et planifiez votre semaine en toute simplicité.',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF6750A4),
    ),
    OnboardingStep(
      title: 'Créez vos tâches',
      description: 'Ajoutez facilement vos tâches avec des rappels, des catégories et des priorités personnalisées.',
      icon: Icons.add_task_rounded,
      color: Color(0xFF2196F3),
    ),
    OnboardingStep(
      title: 'Planifiez votre temps',
      description: 'Visualisez votre emploi du temps quotidien et hebdomadaire avec une interface intuitive.',
      icon: Icons.schedule_rounded,
      color: Color(0xFF4CAF50),
    ),
    OnboardingStep(
      title: 'Recevez des rappels',
      description: 'Ne manquez plus jamais une tâche importante grâce aux notifications intelligentes.',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFFFF9800),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(theme),
            
            // Contenu des pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingStep(context, _steps[index], theme);
                },
              ),
            ),
            
            // Boutons de navigation
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  /// Construit l'indicateur de progression
  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _steps.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Construit une étape d'onboarding
  Widget _buildOnboardingStep(BuildContext context, OnboardingStep step, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 64,
              color: step.color,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Titre
          Text(
            step.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            step.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Contenu spécial pour la page des notifications
          if (_currentPage == 3) ...[
            const SizedBox(height: 32),
            _buildNotificationPermissionCard(theme),
          ],
        ],
      ),
    );
  }

  /// Construit la carte de permission des notifications
  Widget _buildNotificationPermissionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.security_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Autoriser les notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pour vous rappeler vos tâches importantes au bon moment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les boutons de navigation
  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Bouton Précédent
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                child: const Text('Précédent'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          // Bouton Suivant/Terminer
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: FilledButton(
              onPressed: _isLoading ? null : _nextPage,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentPage == _steps.length - 1 ? 'Commencer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  /// Page précédente
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Page suivante ou terminer l'onboarding
  Future<void> _nextPage() async {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  /// Termine l'onboarding
  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Demander les permissions de notifications
      await NotificationService.initialize();
      
      // Marquer l'onboarding comme terminé
      await ref.read(settingsProvider.notifier).completeOnboarding();
      
      // Naviguer vers la page principale
      if (mounted) {
        context.go('/today');
      }
    } catch (e) {
      // En cas d'erreur, continuer quand même
      debugPrint('Erreur lors de la finalisation de l\'onboarding: $e');
      
      if (mounted) {
        // Marquer l'onboarding comme terminé même en cas d'erreur
        await ref.read(settingsProvider.notifier).completeOnboarding();
        context.go('/today');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Classe représentant une étape d'onboarding
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

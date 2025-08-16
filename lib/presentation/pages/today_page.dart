import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/timezone_service.dart';
import '../widgets/task_card.dart';
import '../widgets/timeline_view.dart';
import '../widgets/empty_state.dart';

/// Page "Aujourd'hui" avec timeline et tâches du jour
class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayTasks = ref.watch(todayTasksProvider);
    final categories = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(theme, todayTasks),
            _buildTabBar(theme),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimelineTab(todayTasks, categories, theme),
            _buildTasksTab(todayTasks, categories, theme),
          ],
        ),
      ),
    );
  }

  /// Construit l'AppBar avec les informations du jour
  Widget _buildAppBar(ThemeData theme, List<Task> todayTasks) {
    final now = DateTime.now();
    final completedTasks = todayTasks.where((task) => task.isCompleted).length;
    final totalTasks = todayTasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return SliverAppBar.large(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimezoneService.formatRelativeDate(now),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _getFormattedDate(now),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        _buildProgressIndicator(theme, progress, completedTasks, totalTasks),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }

  /// Construit l'indicateur de progression
  Widget _buildProgressIndicator(
    ThemeData theme,
    double progress,
    int completed,
    int total,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completed/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre d'onglets
  Widget _buildTabBar(ThemeData theme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.schedule_rounded),
              text: 'Timeline',
            ),
            Tab(
              icon: Icon(Icons.checklist_rounded),
              text: 'Tâches',
            ),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        ),
        theme.colorScheme.surface,
      ),
    );
  }

  /// Construit l'onglet Timeline
  Widget _buildTimelineTab(
    List<Task> todayTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    if (todayTasks.isEmpty) {
      return EmptyState(
        icon: Icons.today_outlined,
        title: 'Aucune tâche aujourd\'hui',
        description: 'Profitez de cette journée libre ou ajoutez une nouvelle tâche.',
        actionLabel: 'Ajouter une tâche',
        onActionPressed: () => context.go('/today/new'),
      );
    }

    return TimelineView(
      tasks: todayTasks,
      categories: categories,
      onTaskTap: (task) => context.go('/today/task/${task.id}'),
      onTaskEdit: (task) => context.go('/today/edit/${task.id}'),
      onTaskToggle: (task) => _toggleTaskStatus(task),
      onTimeSlotTap: (dateTime) => _createTaskAtTime(dateTime),
    );
  }

  /// Construit l'onglet Tâches
  Widget _buildTasksTab(
    List<Task> todayTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    if (todayTasks.isEmpty) {
      return EmptyState(
        icon: Icons.checklist_outlined,
        title: 'Aucune tâche aujourd\'hui',
        description: 'Commencez votre journée en ajoutant une première tâche.',
        actionLabel: 'Ajouter une tâche',
        onActionPressed: () => context.go('/today/new'),
      );
    }

    // Grouper les tâches par statut
    final todoTasks = todayTasks.where((task) => task.status == TaskStatus.todo).toList();
    final inProgressTasks = todayTasks.where((task) => task.status == TaskStatus.inProgress).toList();
    final completedTasks = todayTasks.where((task) => task.status == TaskStatus.done).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Prochaine tâche
        if (todoTasks.isNotEmpty || inProgressTasks.isNotEmpty) ...[
          _buildNextTaskCard(
            inProgressTasks.isNotEmpty ? inProgressTasks.first : todoTasks.first,
            categories,
            theme,
          ),
          const SizedBox(height: 24),
        ],

        // Tâches en cours
        if (inProgressTasks.isNotEmpty) ...[
          _buildSectionHeader('En cours', inProgressTasks.length, theme),
          const SizedBox(height: 12),
          ...inProgressTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(
                  task: task,
                  category: _getCategoryForTask(task, categories),
                  onTap: () => context.go('/today/task/${task.id}'),
                  onEdit: () => context.go('/today/edit/${task.id}'),
                  onToggle: () => _toggleTaskStatus(task),
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Tâches à faire
        if (todoTasks.isNotEmpty) ...[
          _buildSectionHeader('À faire', todoTasks.length, theme),
          const SizedBox(height: 12),
          ...todoTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(
                  task: task,
                  category: _getCategoryForTask(task, categories),
                  onTap: () => context.go('/today/task/${task.id}'),
                  onEdit: () => context.go('/today/edit/${task.id}'),
                  onToggle: () => _toggleTaskStatus(task),
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Tâches terminées
        if (completedTasks.isNotEmpty) ...[
          _buildSectionHeader('Terminées', completedTasks.length, theme),
          const SizedBox(height: 12),
          ...completedTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(
                  task: task,
                  category: _getCategoryForTask(task, categories),
                  onTap: () => context.go('/today/task/${task.id}'),
                  onEdit: () => context.go('/today/edit/${task.id}'),
                  onToggle: () => _toggleTaskStatus(task),
                ),
              )),
        ],

        // Espace pour le FAB
        const SizedBox(height: 80),
      ],
    );
  }

  /// Construit la carte de la prochaine tâche
  Widget _buildNextTaskCard(Task nextTask, List<Category> categories, ThemeData theme) {
    final category = _getCategoryForTask(nextTask, categories);
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prochaine tâche',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nextTask.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nextTask.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  nextTask.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: category.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TimezoneService.formatTime(nextTask.startAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => context.go('/today/task/${nextTask.id}'),
                    child: const Text('Voir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un en-tête de section
  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Obtient la catégorie d'une tâche
  Category? _getCategoryForTask(Task task, List<Category> categories) {
    if (task.categoryId == null) return null;
    try {
      return categories.firstWhere((cat) => cat.id == task.categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Bascule le statut d'une tâche
  Future<void> _toggleTaskStatus(Task task) async {
    await ref.read(tasksProvider.notifier).toggleTaskStatus(task.id);
  }

  /// Crée une tâche à une heure spécifique
  void _createTaskAtTime(DateTime dateTime) {
    context.go('/today/new', extra: {'initialDateTime': dateTime});
  }

  /// Formate la date complète
  String _getFormattedDate(DateTime date) {
    const weekdays = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$weekday $day $month $year';
  }
}

/// Delegate pour la barre d'onglets persistante
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

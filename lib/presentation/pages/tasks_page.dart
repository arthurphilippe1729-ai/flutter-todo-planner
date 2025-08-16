import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';

/// Page de gestion de toutes les tâches
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasks = ref.watch(sortedTasksProvider);
    final categories = ref.watch(activeCategoriesProvider);
    final searchResults = ref.watch(taskSearchProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(theme, allTasks),
            _buildTabBar(theme),
          ];
        },
        body: _isSearching
            ? _buildSearchResults(searchResults, categories, theme)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTasksTab(allTasks, categories, theme),
                  _buildTodoTasksTab(allTasks, categories, theme),
                  _buildInProgressTasksTab(allTasks, categories, theme),
                  _buildCompletedTasksTab(allTasks, categories, theme),
                ],
              ),
      ),
    );
  }

  /// Construit l'AppBar avec recherche
  Widget _buildAppBar(ThemeData theme, List<Task> allTasks) {
    return SliverAppBar.large(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Rechercher des tâches...',
                border: InputBorder.none,
              ),
              onChanged: (query) {
                ref.read(taskSearchProvider.notifier).search(query);
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tâches'),
                Text(
                  '${allTasks.length} tâche${allTasks.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
      actions: [
        if (_isSearching)
          IconButton(
            onPressed: _stopSearch,
            icon: const Icon(Icons.close_rounded),
          )
        else ...[
          IconButton(
            onPressed: _startSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort_rounded),
                  title: Text('Trier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list_rounded),
                  title: Text('Filtrer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Construit la barre d'onglets
  Widget _buildTabBar(ThemeData theme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'À faire'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        ),
        theme.colorScheme.surface,
      ),
    );
  }

  /// Construit l'onglet de toutes les tâches
  Widget _buildAllTasksTab(
    List<Task> allTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    if (allTasks.isEmpty) {
      return EmptyStates.allTasks(
        onAddTask: () => context.go('/tasks/new'),
      );
    }

    return _buildTasksList(allTasks, categories, theme);
  }

  /// Construit l'onglet des tâches à faire
  Widget _buildTodoTasksTab(
    List<Task> allTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    final todoTasks = allTasks.where((task) => task.status == TaskStatus.todo).toList();

    if (todoTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_outlined,
        title: 'Aucune tâche à faire',
        description: 'Toutes vos tâches sont soit en cours, soit terminées.',
      );
    }

    return _buildTasksList(todoTasks, categories, theme);
  }

  /// Construit l'onglet des tâches en cours
  Widget _buildInProgressTasksTab(
    List<Task> allTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    final inProgressTasks = allTasks.where((task) => task.status == TaskStatus.inProgress).toList();

    if (inProgressTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.play_circle_outline_rounded,
        title: 'Aucune tâche en cours',
        description: 'Commencez à travailler sur une tâche pour qu\'elle apparaisse ici.',
      );
    }

    return _buildTasksList(inProgressTasks, categories, theme);
  }

  /// Construit l'onglet des tâches terminées
  Widget _buildCompletedTasksTab(
    List<Task> allTasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    final completedTasks = allTasks.where((task) => task.status == TaskStatus.done).toList();

    if (completedTasks.isEmpty) {
      return EmptyStates.completedTasks();
    }

    return _buildTasksList(completedTasks, categories, theme);
  }

  /// Construit les résultats de recherche
  Widget _buildSearchResults(
    List<Task> searchResults,
    List<Category> categories,
    ThemeData theme,
  ) {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text('Tapez pour rechercher des tâches...'),
      );
    }

    if (searchResults.isEmpty) {
      return EmptyStates.searchResults(query: _searchController.text);
    }

    return _buildTasksList(searchResults, categories, theme);
  }

  /// Construit la liste des tâches
  Widget _buildTasksList(
    List<Task> tasks,
    List<Category> categories,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length + 1, // +1 pour l'espace du FAB
      itemBuilder: (context, index) {
        if (index == tasks.length) {
          return const SizedBox(height: 80); // Espace pour le FAB
        }

        final task = tasks[index];
        final category = _getCategoryForTask(task, categories);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            category: category,
            onTap: () => context.go('/tasks/task/${task.id}'),
            onEdit: () => context.go('/tasks/edit/${task.id}'),
            onToggle: () => _toggleTaskStatus(task),
          ),
        );
      },
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

  /// Démarre la recherche
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  /// Arrête la recherche
  void _stopSearch() {
    setState(() {
      _isSearching = false;
    });
    _searchController.clear();
    ref.read(taskSearchProvider.notifier).clear();
  }

  /// Gère les actions du menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortDialog();
        break;
      case 'filter':
        _showFilterDialog();
        break;
    }
  }

  /// Affiche le dialogue de tri
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trier par'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date'),
              leading: const Icon(Icons.schedule_rounded),
              onTap: () {
                ref.read(taskSortProvider.notifier).setSortType(TaskSortType.date);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Priorité'),
              leading: const Icon(Icons.priority_high_rounded),
              onTap: () {
                ref.read(taskSortProvider.notifier).setSortType(TaskSortType.priority);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Titre'),
              leading: const Icon(Icons.sort_by_alpha_rounded),
              onTap: () {
                ref.read(taskSortProvider.notifier).setSortType(TaskSortType.title);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Statut'),
              leading: const Icon(Icons.check_circle_outline_rounded),
              onTap: () {
                ref.read(taskSortProvider.notifier).setSortType(TaskSortType.status);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue de filtres
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: const Text('Fonctionnalité de filtrage à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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

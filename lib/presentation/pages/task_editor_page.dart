import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/timezone_service.dart';

/// Page d'édition/création de tâche
class TaskEditorPage extends ConsumerStatefulWidget {
  final String? taskId;
  final DateTime? initialDateTime;

  const TaskEditorPage({
    super.key,
    this.taskId,
    this.initialDateTime,
  });

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  
  bool _isAllDay = false;
  TaskPriority _priority = TaskPriority.medium;
  String? _selectedCategoryId;
  final List<String> _tags = [];
  final List<int> _reminders = [];
  
  bool _isLoading = false;
  Task? _originalTask;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final now = DateTime.now();
    final settings = ref.read(settingsProvider);
    
    if (widget.taskId != null) {
      // Mode édition
      _originalTask = ref.read(taskByIdProvider(widget.taskId!));
      if (_originalTask != null) {
        _titleController.text = _originalTask!.title;
        _descriptionController.text = _originalTask!.description ?? '';
        _startDate = _originalTask!.startAt;
        _startTime = TimeOfDay.fromDateTime(_originalTask!.startAt);
        _endDate = _originalTask!.endAt;
        _endTime = TimeOfDay.fromDateTime(_originalTask!.endAt);
        _isAllDay = _originalTask!.isAllDay;
        _priority = _originalTask!.priority;
        _selectedCategoryId = _originalTask!.categoryId;
        _tags.addAll(_originalTask!.tags);
        _reminders.addAll(_originalTask!.reminders);
      }
    } else {
      // Mode création
      final initialDateTime = widget.initialDateTime ?? now;
      _startDate = initialDateTime;
      _startTime = TimeOfDay.fromDateTime(initialDateTime);
      
      // Calculer l'heure de fin basée sur la durée par défaut
      final defaultDuration = settings.defaultTaskDuration;
      final endDateTime = initialDateTime.add(Duration(minutes: defaultDuration));
      _endDate = endDateTime;
      _endTime = TimeOfDay.fromDateTime(endDateTime);
      
      // Sélectionner la catégorie par défaut
      final defaultCategory = ref.read(defaultCategoryProvider);
      _selectedCategoryId = defaultCategory?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(activeCategoriesProvider);
    final isEditing = widget.taskId != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        title: Text(isEditing ? 'Modifier la tâche' : 'Nouvelle tâche'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            _buildTitleField(theme),
            
            const SizedBox(height: 16),
            
            // Description
            _buildDescriptionField(theme),
            
            const SizedBox(height: 24),
            
            // Date et heure
            _buildDateTimeSection(theme),
            
            const SizedBox(height: 24),
            
            // Priorité
            _buildPrioritySection(theme),
            
            const SizedBox(height: 24),
            
            // Catégorie
            _buildCategorySection(categories, theme),
            
            const SizedBox(height: 24),
            
            // Tags
            _buildTagsSection(theme),
            
            const SizedBox(height: 24),
            
            // Rappels
            _buildRemindersSection(theme),
            
            const SizedBox(height: 80), // Espace pour les actions
          ],
        ),
      ),
    );
  }

  /// Construit le champ titre
  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Titre *',
        hintText: 'Entrez le titre de la tâche',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le titre est obligatoire';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// Construit le champ description
  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Ajoutez une description (optionnel)',
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// Construit la section date et heure
  Widget _buildDateTimeSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date et heure',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Toute la journée
            SwitchListTile(
              title: const Text('Toute la journée'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            // Date de début
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Date de début'),
              subtitle: Text(TimezoneService.formatRelativeDate(_startDate)),
              onTap: () => _selectStartDate(),
              contentPadding: EdgeInsets.zero,
            ),
            
            // Heure de début
            if (!_isAllDay)
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Heure de début'),
                subtitle: Text(_startTime.format(context)),
                onTap: () => _selectStartTime(),
                contentPadding: EdgeInsets.zero,
              ),
            
            // Date de fin (si différente)
            if (!_isSameDay(_startDate, _endDate))
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date de fin'),
                subtitle: Text(TimezoneService.formatRelativeDate(_endDate)),
                onTap: () => _selectEndDate(),
                contentPadding: EdgeInsets.zero,
              ),
            
            // Heure de fin
            if (!_isAllDay)
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Heure de fin'),
                subtitle: Text(_endTime.format(context)),
                onTap: () => _selectEndTime(),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  /// Construit la section priorité
  Widget _buildPrioritySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priorité',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                final isSelected = _priority == priority;
                return FilterChip(
                  label: Text(priority.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _priority = priority;
                      });
                    }
                  },
                  avatar: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${priority.colorHex.substring(1)}', radix: 16)),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section catégorie
  Widget _buildCategorySection(List<Category> categories, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Option "Aucune"
                FilterChip(
                  label: const Text('Aucune'),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    }
                  },
                ),
                
                // Catégories disponibles
                ...categories.map((category) {
                  final isSelected = _selectedCategoryId == category.id;
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.id : null;
                      });
                    },
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section tags
  Widget _buildTagsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tags',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit la section rappels
  Widget _buildRemindersSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Rappels',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addReminder,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            
            if (_reminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._reminders.map((minutes) {
                return ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(_formatReminderTime(minutes)),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _reminders.remove(minutes);
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Sélectionne la date de début
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        // Ajuster la date de fin si nécessaire
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  /// Sélectionne l'heure de début
  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
        // Ajuster l'heure de fin si nécessaire
        final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, time.hour, time.minute);
        final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
        
        if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
          final newEndTime = startDateTime.add(const Duration(hours: 1));
          _endTime = TimeOfDay.fromDateTime(newEndTime);
          if (!_isSameDay(_startDate, _endDate)) {
            _endDate = DateTime(newEndTime.year, newEndTime.month, newEndTime.day);
          }
        }
      });
    }
  }

  /// Sélectionne la date de fin
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  /// Sélectionne l'heure de fin
  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  /// Ajoute un tag
  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nom du tag',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  /// Ajoute un rappel
  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) {
        int selectedMinutes = 15;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter un rappel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('5 minutes avant'),
                    value: 5,
                    groupValue: selectedMinutes,
                    onChanged: (value) => setState(() => selectedMinutes = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('15 minutes avant'),
                    value: 15,
                    groupValue: selectedMinutes,
                    onChanged: (value) => setState(() => selectedMinutes = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('30 minutes avant'),
                    value: 30,
                    groupValue: selectedMinutes,
                    onChanged: (value) => setState(() => selectedMinutes = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('1 heure avant'),
                    value: 60,
                    groupValue: selectedMinutes,
                    onChanged: (value) => setState(() => selectedMinutes = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!_reminders.contains(selectedMinutes)) {
                      setState(() {
                        _reminders.add(selectedMinutes);
                        _reminders.sort((a, b) => b.compareTo(a));
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Sauvegarde la tâche
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      
      final endDateTime = _isAllDay
          ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59)
          : DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

      if (widget.taskId != null) {
        // Mode édition
        final updatedTask = _originalTask!.update(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          isAllDay: _isAllDay,
          priority: _priority,
          categoryId: _selectedCategoryId,
          tags: _tags,
          reminders: _reminders,
        );
        
        await ref.read(tasksProvider.notifier).updateTask(updatedTask);
      } else {
        // Mode création
        final newTask = Task.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          startAt: startDateTime,
          endAt: endDateTime,
          isAllDay: _isAllDay,
          priority: _priority,
          categoryId: _selectedCategoryId,
          tags: _tags,
          reminders: _reminders,
        );
        
        await ref.read(tasksProvider.notifier).addTask(newTask);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Vérifie si deux dates sont le même jour
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Formate le temps de rappel
  String _formatReminderTime(int minutes) {
    if (minutes == 0) {
      return 'À l\'heure de début';
    } else if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''} avant';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''} avant';
      } else {
        return '${hours}h${remainingMinutes}min avant';
      }
    }
  }
}

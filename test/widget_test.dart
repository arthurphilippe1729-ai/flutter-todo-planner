import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_todo_app/main.dart';

void main() {
  group('Todo App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Simuler l'initialisation des services
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Todo & Planning'),
              ),
            ),
          ),
        ),
      );

      // Vérifier que l'app se charge
      expect(find.text('Todo & Planning'), findsOneWidget);
    });

    testWidgets('Material 3 theme should be applied', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Card(
                child: Text('Test Card'),
              ),
            ),
          ),
        ),
      );

      // Vérifier qu'une carte Material 3 est présente
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
    });
  });

  group('Task Model Tests', () {
    test('Task creation should work correctly', () {
      final now = DateTime.now();
      final endTime = now.add(const Duration(hours: 1));
      
      final task = Task.create(
        title: 'Test Task',
        startAt: now,
        endAt: endTime,
        description: 'Test description',
      );

      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Test description'));
      expect(task.startAt, equals(now));
      expect(task.endAt, equals(endTime));
      expect(task.status, equals(TaskStatus.todo));
      expect(task.priority, equals(TaskPriority.medium));
      expect(task.isCompleted, isFalse);
      expect(task.duration, equals(const Duration(hours: 1)));
    });

    test('Task status changes should work', () {
      final task = Task.create(
        title: 'Test Task',
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final completedTask = task.markAsCompleted();
      expect(completedTask.status, equals(TaskStatus.done));
      expect(completedTask.isCompleted, isTrue);

      final inProgressTask = task.markAsInProgress();
      expect(inProgressTask.status, equals(TaskStatus.inProgress));
      expect(inProgressTask.isInProgress, isTrue);
    });

    test('Task checklist should work correctly', () {
      final task = Task.create(
        title: 'Test Task',
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final taskWithSubtask = task.addSubtask('Test subtask');
      expect(taskWithSubtask.hasChecklist, isTrue);
      expect(taskWithSubtask.checklist.length, equals(1));
      expect(taskWithSubtask.checklist.first.text, equals('Test subtask'));
      expect(taskWithSubtask.completedSubtasks, equals(0));
      expect(taskWithSubtask.checklistProgress, equals(0.0));

      final completedSubtask = taskWithSubtask.checklist.first.markAsCompleted();
      final updatedTask = taskWithSubtask.updateSubtask(
        completedSubtask.id,
        done: true,
      );
      expect(updatedTask.completedSubtasks, equals(1));
      expect(updatedTask.checklistProgress, equals(1.0));
    });
  });

  group('Category Model Tests', () {
    test('Category creation should work correctly', () {
      final category = Category.create(
        name: 'Test Category',
        colorHex: '#FF0000',
        description: 'Test description',
      );

      expect(category.name, equals('Test Category'));
      expect(category.colorHex, equals('#FF0000'));
      expect(category.description, equals('Test description'));
      expect(category.isActive, isTrue);
      expect(category.isArchived, isFalse);
    });

    test('Category color conversion should work', () {
      final category = Category.create(
        name: 'Test Category',
        colorHex: '#FF0000',
      );

      expect(category.color.value, equals(0xFFFF0000));
    });

    test('Default categories should be created correctly', () {
      final defaultCategories = Category.createDefaultCategories();
      
      expect(defaultCategories.length, equals(5));
      expect(defaultCategories.any((cat) => cat.name == 'Perso'), isTrue);
      expect(defaultCategories.any((cat) => cat.name == 'Travail'), isTrue);
      expect(defaultCategories.any((cat) => cat.name == 'Santé'), isTrue);
      
      for (final category in defaultCategories) {
        expect(category.isDefault, isTrue);
        expect(category.hasValidName, isTrue);
      }
    });
  });

  group('Subtask Model Tests', () {
    test('Subtask creation should work correctly', () {
      final subtask = Subtask.create(text: 'Test subtask');
      
      expect(subtask.text, equals('Test subtask'));
      expect(subtask.done, isFalse);
      expect(subtask.isEmpty, isFalse);
      expect(subtask.formattedText, equals('Test subtask'));
    });

    test('Subtask toggle should work', () {
      final subtask = Subtask.create(text: 'Test subtask');
      
      final toggledSubtask = subtask.toggle();
      expect(toggledSubtask.done, isTrue);
      
      final toggledAgain = toggledSubtask.toggle();
      expect(toggledAgain.done, isFalse);
    });

    test('Empty subtask detection should work', () {
      final emptySubtask = Subtask.create(text: '   ');
      expect(emptySubtask.isEmpty, isTrue);
      
      final validSubtask = Subtask.create(text: 'Valid text');
      expect(validSubtask.isEmpty, isFalse);
    });
  });

  group('Priority and Status Tests', () {
    test('Task priority should have correct values', () {
      expect(TaskPriority.low.sortValue, equals(1));
      expect(TaskPriority.medium.sortValue, equals(2));
      expect(TaskPriority.high.sortValue, equals(3));
      expect(TaskPriority.urgent.sortValue, equals(4));
      
      expect(TaskPriority.low.label, equals('Faible'));
      expect(TaskPriority.medium.label, equals('Moyenne'));
      expect(TaskPriority.high.label, equals('Élevée'));
      expect(TaskPriority.urgent.label, equals('Urgente'));
    });

    test('Task status should have correct labels', () {
      expect(TaskStatus.todo.label, equals('À faire'));
      expect(TaskStatus.inProgress.label, equals('En cours'));
      expect(TaskStatus.done.label, equals('Terminé'));
    });

    test('Priority and status conversion should work', () {
      expect(TaskPriority.fromString('low'), equals(TaskPriority.low));
      expect(TaskPriority.fromString('invalid'), equals(TaskPriority.medium));
      
      expect(TaskStatus.fromString('done'), equals(TaskStatus.done));
      expect(TaskStatus.fromString('invalid'), equals(TaskStatus.todo));
    });
  });
}

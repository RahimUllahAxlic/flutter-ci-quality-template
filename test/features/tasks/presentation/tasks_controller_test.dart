import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  const open = Task(id: '1', title: 'Open');
  const done = Task(id: '2', title: 'Done', isDone: true);

  late MockTaskRepository repository;
  late TasksController controller;

  setUp(() {
    repository = MockTaskRepository();
    controller = TasksController(repository);
  });

  Future<void> loadWith(List<Task> tasks) async {
    when(() => repository.fetchAll()).thenAnswer((_) async => tasks);
    await controller.load();
  }

  group('load', () {
    test('starts in the loading state', () {
      expect(controller.status.value, TasksStatus.loading);
    });

    test('moves to ready with the fetched tasks', () async {
      await loadWith([open, done]);

      expect(controller.status.value, TasksStatus.ready);
      expect(controller.tasks, [open, done]);
    });

    test('moves to failure and reports an error when fetching throws',
        () async {
      when(() => repository.fetchAll()).thenThrow(Exception('boom'));

      await controller.load();

      expect(controller.status.value, TasksStatus.failure);
      expect(controller.errorMessage.value, 'Could not load tasks.');
    });
  });

  group('add', () {
    test('appends the created task and returns true', () async {
      await loadWith([open]);
      when(() => repository.add('New'))
          .thenAnswer((_) async => const Task(id: '3', title: 'New'));

      final added = await controller.add('New');

      expect(added, isTrue);
      expect(controller.tasks.map((t) => t.title), ['Open', 'New']);
    });

    test('rejects blank input without calling the repository', () async {
      final added = await controller.add('   ');

      expect(added, isFalse);
      expect(controller.errorMessage.value, 'Task title cannot be empty.');
      verifyNever(() => repository.add(any()));
    });

    test('reports an error when the repository fails', () async {
      when(() => repository.add(any())).thenThrow(Exception('boom'));

      final added = await controller.add('New');

      expect(added, isFalse);
      expect(controller.errorMessage.value, 'Could not add the task.');
    });
  });

  group('toggle', () {
    test('replaces the task with the updated one', () async {
      await loadWith([open]);
      when(() => repository.toggle('1'))
          .thenAnswer((_) async => open.copyWith(isDone: true));

      await controller.toggle('1');

      expect(controller.tasks.single.isDone, isTrue);
    });

    test('reports an error when the repository fails', () async {
      when(() => repository.toggle(any()))
          .thenThrow(const TaskNotFoundException('1'));

      await controller.toggle('1');

      expect(controller.errorMessage.value, 'Could not update the task.');
    });
  });

  group('remove', () {
    test('drops the task from the list', () async {
      await loadWith([open, done]);
      when(() => repository.remove('1')).thenAnswer((_) async {});

      await controller.remove('1');

      expect(controller.tasks, [done]);
    });

    test('keeps the list intact and reports an error on failure', () async {
      await loadWith([open]);
      when(() => repository.remove(any())).thenThrow(Exception('boom'));

      await controller.remove('1');

      expect(controller.tasks, [open]);
      expect(controller.errorMessage.value, 'Could not delete the task.');
    });
  });

  group('filtering', () {
    setUp(() async => loadWith([open, done]));

    test('all shows everything', () {
      expect(controller.visibleTasks, [open, done]);
    });

    test('active shows only unfinished tasks', () {
      controller.setFilter(TaskFilter.active);

      expect(controller.visibleTasks, [open]);
    });

    test('completed shows only finished tasks', () {
      controller.setFilter(TaskFilter.completed);

      expect(controller.visibleTasks, [done]);
    });

    test('remainingCount counts unfinished tasks regardless of filter', () {
      controller.setFilter(TaskFilter.completed);

      expect(controller.remainingCount, 1);
    });
  });

  test('clearError resets the error message', () async {
    await controller.add('');
    expect(controller.errorMessage.value, isNotNull);

    controller.clearError();

    expect(controller.errorMessage.value, isNull);
  });
}

import 'package:flutter_ci_quality_template/features/tasks/data/in_memory_task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryTaskRepository', () {
    late InMemoryTaskRepository repository;

    setUp(() => repository = InMemoryTaskRepository());

    test('starts empty', () async {
      expect(await repository.fetchAll(), isEmpty);
    });

    test('returns the seed data', () async {
      const seed = [Task(id: 's1', title: 'Seeded')];
      final seeded = InMemoryTaskRepository(seed: seed);

      expect(await seeded.fetchAll(), seed);
    });

    test('add trims the title and assigns unique ids', () async {
      final first = await repository.add('  First  ');
      final second = await repository.add('Second');

      expect(first.title, 'First');
      expect(first.id, isNot(second.id));
      expect(await repository.fetchAll(), [first, second]);
    });

    test('add rejects blank titles', () {
      expect(() => repository.add('   '), throwsArgumentError);
    });

    test('toggle flips completion both ways', () async {
      final task = await repository.add('Toggle me');

      final done = await repository.toggle(task.id);
      final undone = await repository.toggle(task.id);

      expect(done.isDone, isTrue);
      expect(undone.isDone, isFalse);
    });

    test('remove deletes the task', () async {
      final task = await repository.add('Remove me');

      await repository.remove(task.id);

      expect(await repository.fetchAll(), isEmpty);
    });

    test('toggle and remove throw for unknown ids', () {
      expect(
        () => repository.toggle('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
      expect(
        () => repository.remove('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('fetchAll returns an unmodifiable snapshot', () async {
      await repository.add('One');
      final snapshot = await repository.fetchAll();

      expect(
        () => snapshot.add(const Task(id: 'x', title: 'x')),
        throwsUnsupportedError,
      );
    });
  });
}

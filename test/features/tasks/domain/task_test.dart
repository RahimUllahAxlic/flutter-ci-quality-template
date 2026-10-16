import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task', () {
    test('copyWith changes only the requested fields', () {
      const task = Task(id: '1', title: 'Write tests');

      final updated = task.copyWith(isDone: true);

      expect(updated.id, '1');
      expect(updated.title, 'Write tests');
      expect(updated.isDone, isTrue);
    });

    test('has value equality', () {
      const a = Task(id: '1', title: 'A');
      const b = Task(id: '1', title: 'A');
      const c = Task(id: '1', title: 'A', isDone: true);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

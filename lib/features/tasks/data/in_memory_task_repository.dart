import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';

/// [TaskRepository] backed by a list in memory. Good for demos and tests;
/// replace with a remote or local-database implementation for real apps.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({List<Task> seed = const []})
      : _tasks = List<Task>.of(seed);

  final List<Task> _tasks;
  int _nextId = 0;

  @override
  Future<List<Task>> fetchAll() async => List<Task>.unmodifiable(_tasks);

  @override
  Future<Task> add(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be blank');
    }
    final task = Task(id: 'task-${_nextId++}', title: trimmed);
    _tasks.add(task);
    return task;
  }

  @override
  Future<Task> toggle(String id) async {
    final index = _indexOf(id);
    final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> remove(String id) async {
    _tasks.removeAt(_indexOf(id));
  }

  int _indexOf(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    return index;
  }
}

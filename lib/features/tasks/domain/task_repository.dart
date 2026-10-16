import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';

/// Thrown when an operation references a task that does not exist.
class TaskNotFoundException implements Exception {
  const TaskNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'TaskNotFoundException: no task with id "$id"';
}

/// Persistence contract for tasks. The presentation layer depends on this
/// interface only, never on a concrete data source.
abstract interface class TaskRepository {
  Future<List<Task>> fetchAll();

  /// Creates a task. Throws [ArgumentError] when [title] is blank.
  Future<Task> add(String title);

  /// Flips completion. Throws [TaskNotFoundException] for unknown ids.
  Future<Task> toggle(String id);

  /// Deletes a task. Throws [TaskNotFoundException] for unknown ids.
  Future<void> remove(String id);
}

import 'dart:async';

import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:get/get.dart';

enum TasksStatus { loading, ready, failure }

enum TaskFilter { all, active, completed }

/// Presentation logic for the task list.
///
/// Depends on [TaskRepository] (an interface), exposes reactive state via
/// GetX observables, and contains no Flutter widgets, so it is unit-testable
/// without a widget tree.
class TasksController extends GetxController {
  TasksController(this._repository);

  final TaskRepository _repository;

  final tasks = <Task>[].obs;
  final status = TasksStatus.loading.obs;
  final filter = TaskFilter.all.obs;
  final errorMessage = RxnString();

  List<Task> get visibleTasks => switch (filter.value) {
        TaskFilter.all => tasks.toList(),
        TaskFilter.active => tasks.where((t) => !t.isDone).toList(),
        TaskFilter.completed => tasks.where((t) => t.isDone).toList(),
      };

  int get remainingCount => tasks.where((t) => !t.isDone).length;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    status.value = TasksStatus.loading;
    try {
      tasks.assignAll(await _repository.fetchAll());
      errorMessage.value = null;
      status.value = TasksStatus.ready;
    } on Object {
      errorMessage.value = 'Could not load tasks.';
      status.value = TasksStatus.failure;
    }
  }

  /// Returns `true` when the task was added.
  Future<bool> add(String title) async {
    if (title.trim().isEmpty) {
      errorMessage.value = 'Task title cannot be empty.';
      return false;
    }
    return _run(
      () async => tasks.add(await _repository.add(title)),
      'Could not add the task.',
    );
  }

  Future<void> toggle(String id) async {
    await _run(() async {
      final updated = await _repository.toggle(id);
      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1) tasks[index] = updated;
    }, 'Could not update the task.');
  }

  Future<void> remove(String id) async {
    await _run(() async {
      await _repository.remove(id);
      tasks.removeWhere((t) => t.id == id);
    }, 'Could not delete the task.');
  }

  void setFilter(TaskFilter value) => filter.value = value;

  void clearError() => errorMessage.value = null;

  /// Runs [action]; on any failure surfaces [failureMessage] instead of
  /// letting the exception escape into the UI.
  Future<bool> _run(
    Future<void> Function() action,
    String failureMessage,
  ) async {
    try {
      await action();
      errorMessage.value = null;
      return true;
    } on Object {
      errorMessage.value = failureMessage;
      return false;
    }
  }
}

import 'package:flutter_ci_quality_template/features/tasks/data/in_memory_task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:get/get.dart';

/// Composition root: wires interfaces to implementations for the whole app.
///
/// Swapping the in-memory repository for a REST or database-backed one is a
/// one-line change here; nothing above the domain layer needs to know.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TaskRepository>(
      InMemoryTaskRepository(
        seed: const [
          Task(id: 'seed-1', title: 'Review pull request'),
          Task(id: 'seed-2', title: 'Cut the release', isDone: true),
        ],
      ),
      permanent: true,
    );
  }
}

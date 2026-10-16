import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_controller.dart';
import 'package:get/get.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TasksController>(
      () => TasksController(Get.find<TaskRepository>()),
    );
  }
}

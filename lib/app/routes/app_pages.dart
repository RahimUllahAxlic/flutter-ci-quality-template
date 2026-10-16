import 'package:flutter_ci_quality_template/app/routes/app_routes.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_binding.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_page.dart';
import 'package:get/get.dart';

/// Route table. Each page declares the binding that owns its controller, so
/// controllers are created lazily and disposed with their route.
abstract final class AppPages {
  static const initial = Routes.tasks;

  static final routes = <GetPage<void>>[
    GetPage<void>(
      name: Routes.tasks,
      page: () => const TasksPage(),
      binding: TasksBinding(),
    ),
  ];
}

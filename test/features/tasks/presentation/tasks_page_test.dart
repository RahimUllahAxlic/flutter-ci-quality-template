import 'package:flutter/material.dart';
import 'package:flutter_ci_quality_template/features/tasks/data/in_memory_task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task.dart';
import 'package:flutter_ci_quality_template/features/tasks/domain/task_repository.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> pumpTasksPage(
  WidgetTester tester, {
  List<Task> seed = const [],
}) async {
  Get.put<TaskRepository>(InMemoryTaskRepository(seed: seed));
  Get.put(TasksController(Get.find<TaskRepository>()));
  await tester.pumpWidget(const GetMaterialApp(home: TasksPage()));
  await tester.pumpAndSettle();
}

void main() {
  const open = Task(id: 't1', title: 'Write docs');
  const done = Task(id: 't2', title: 'Ship it', isDone: true);

  tearDown(Get.reset);

  testWidgets('shows an empty state when there are no tasks', (tester) async {
    await pumpTasksPage(tester);

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('0 remaining'), findsOneWidget);
  });

  testWidgets('lists seeded tasks and the remaining count', (tester) async {
    await pumpTasksPage(tester, seed: [open, done]);

    expect(find.text('Write docs'), findsOneWidget);
    expect(find.text('Ship it'), findsOneWidget);
    expect(find.text('1 remaining'), findsOneWidget);
  });

  testWidgets('adds a task and clears the input', (tester) async {
    await pumpTasksPage(tester);

    await tester.enterText(
      find.byKey(const Key('add_task_field')),
      'Review PR',
    );
    await tester.tap(find.byKey(const Key('add_task_button')));
    await tester.pumpAndSettle();

    // Exactly one match: the list item. The input field was cleared.
    expect(find.text('Review PR'), findsOneWidget);
    expect(find.text('1 remaining'), findsOneWidget);
  });

  testWidgets('shows a dismissible error for blank input', (tester) async {
    await pumpTasksPage(tester);

    await tester.tap(find.byKey(const Key('add_task_button')));
    await tester.pumpAndSettle();
    expect(find.text('Task title cannot be empty.'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Task title cannot be empty.'), findsNothing);
  });

  testWidgets('toggling a task updates the remaining count', (tester) async {
    await pumpTasksPage(tester, seed: [open]);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('task_t1')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 remaining'), findsOneWidget);
  });

  testWidgets('deleting a task removes it from the list', (tester) async {
    await pumpTasksPage(tester, seed: [open, done]);

    await tester.tap(find.byKey(const ValueKey('delete_t1')));
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsNothing);
    expect(find.text('Ship it'), findsOneWidget);
  });

  testWidgets('the Completed filter hides unfinished tasks', (tester) async {
    await pumpTasksPage(tester, seed: [open, done]);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsNothing);
    expect(find.text('Ship it'), findsOneWidget);
  });
}

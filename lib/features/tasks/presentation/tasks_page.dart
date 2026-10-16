import 'package:flutter/material.dart';
import 'package:flutter_ci_quality_template/features/tasks/presentation/tasks_controller.dart';
import 'package:get/get.dart';

class TasksPage extends GetView<TasksController> {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          _AddTaskField(onSubmit: controller.add),
          const _FilterBar(),
          const _ErrorBanner(),
          const Expanded(child: _TaskList()),
        ],
      ),
      bottomNavigationBar: const _RemainingFooter(),
    );
  }
}

class _AddTaskField extends StatefulWidget {
  const _AddTaskField({required this.onSubmit});

  final Future<bool> Function(String title) onSubmit;

  @override
  State<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<_AddTaskField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final added = await widget.onSubmit(_text.text);
    if (added && mounted) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('add_task_field'),
              controller: _text,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'What needs doing?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('add_task_button'),
            tooltip: 'Add task',
            icon: const Icon(Icons.add),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends GetView<TasksController> {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(
        () => SegmentedButton<TaskFilter>(
          segments: const <ButtonSegment<TaskFilter>>[
            ButtonSegment(value: TaskFilter.all, label: Text('All')),
            ButtonSegment(value: TaskFilter.active, label: Text('Active')),
            ButtonSegment(
              value: TaskFilter.completed,
              label: Text('Completed'),
            ),
          ],
          selected: {controller.filter.value},
          onSelectionChanged: (selection) =>
              controller.setFilter(selection.first),
        ),
      ),
    );
  }
}

class _ErrorBanner extends GetView<TasksController> {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.errorMessage.value;
      if (message == null) return const SizedBox.shrink();
      return MaterialBanner(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: controller.clearError,
            child: const Text('Dismiss'),
          ),
        ],
      );
    });
  }
}

class _TaskList extends GetView<TasksController> {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case TasksStatus.loading:
          return const Center(child: CircularProgressIndicator());
        case TasksStatus.failure:
          return Center(
            child: FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          );
        case TasksStatus.ready:
          final tasks = controller.visibleTasks;
          if (tasks.isEmpty) {
            return const Center(child: Text('Nothing here yet'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return CheckboxListTile(
                key: ValueKey('task_${task.id}'),
                value: task.isDone,
                onChanged: (_) => controller.toggle(task.id),
                title: Text(
                  task.title,
                  style: task.isDone
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                secondary: IconButton(
                  key: ValueKey('delete_${task.id}'),
                  tooltip: 'Delete task',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.remove(task.id),
                ),
              );
            },
          );
      }
    });
  }
}

class _RemainingFooter extends GetView<TasksController> {
  const _RemainingFooter();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Text(
            '${controller.remainingCount} remaining',
            key: const Key('remaining_count'),
          ),
        ),
      ),
    );
  }
}

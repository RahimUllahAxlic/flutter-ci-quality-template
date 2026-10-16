import 'package:flutter/foundation.dart';

/// An immutable to-do item.
@immutable
class Task {
  const Task({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  final bool isDone;

  Task copyWith({String? title, bool? isDone}) {
    return Task(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          other.id == id &&
          other.title == title &&
          other.isDone == isDone;

  @override
  int get hashCode => Object.hash(id, title, isDone);

  @override
  String toString() => 'Task(id: $id, title: $title, isDone: $isDone)';
}

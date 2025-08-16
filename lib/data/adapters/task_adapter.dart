import 'package:hive/hive.dart';
import '../../models/task.dart';
import '../../models/subtask.dart';

/// Adapter Hive pour le modèle Task
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      startAt: fields[3] as DateTime,
      endAt: fields[4] as DateTime,
      isAllDay: fields[5] as bool? ?? false,
      recurrenceRule: fields[6] as String?,
      recurrenceEndsAt: fields[7] as DateTime?,
      reminders: (fields[8] as List?)?.cast<int>() ?? [],
      status: fields[9] as TaskStatus? ?? TaskStatus.todo,
      priority: fields[10] as TaskPriority? ?? TaskPriority.medium,
      categoryId: fields[11] as String?,
      tags: (fields[12] as List?)?.cast<String>() ?? [],
      checklist: (fields[13] as List?)?.cast<Subtask>() ?? [],
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startAt)
      ..writeByte(4)
      ..write(obj.endAt)
      ..writeByte(5)
      ..write(obj.isAllDay)
      ..writeByte(6)
      ..write(obj.recurrenceRule)
      ..writeByte(7)
      ..write(obj.recurrenceEndsAt)
      ..writeByte(8)
      ..write(obj.reminders)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.priority)
      ..writeByte(11)
      ..write(obj.categoryId)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.checklist)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Adapter Hive pour l'énumération TaskStatus
class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 1;

  @override
  TaskStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return TaskStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Adapter Hive pour l'énumération TaskPriority
class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 2;

  @override
  TaskPriority read(BinaryReader reader) {
    final index = reader.readByte();
    return TaskPriority.values[index];
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

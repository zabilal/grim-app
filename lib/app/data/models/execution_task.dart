// models/execution_task.dart
class ExecutionTask {
  String id;
  String day; // Mon, Tue, Wed, Thu, Fri
  int startHour;
  String taskType; // Deep Work, Meetings, Workout, etc.
  String? specificTask;
  bool isCompleted;
  DateTime? completedAt;
  bool hasReminder;

  ExecutionTask({
    required this.id,
    required this.day,
    required this.startHour,
    required this.taskType,
    this.specificTask,
    this.isCompleted = false,
    this.completedAt,
    this.hasReminder = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'startHour': startHour,
    'taskType': taskType,
    'specificTask': specificTask,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'hasReminder': hasReminder,
  };

  factory ExecutionTask.fromJson(Map<String, dynamic> json) => ExecutionTask(
    id: json['id'],
    day: json['day'],
    startHour: json['startHour'],
    taskType: json['taskType'],
    specificTask: json['specificTask'],
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    hasReminder: json['hasReminder'] ?? true,
  );
}

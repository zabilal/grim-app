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
  bool isActive; // New field to track if task is currently active
  DateTime? startedAt; // When the task was started

  ExecutionTask({
    required this.id,
    required this.day,
    required this.startHour,
    required this.taskType,
    this.specificTask,
    this.isCompleted = false,
    this.completedAt,
    this.hasReminder = true,
    this.isActive = false,
    this.startedAt,
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
    'isActive': isActive,
    'startedAt': startedAt?.toIso8601String(),
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
    isActive: json['isActive'] ?? false,
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'])
        : null,
  );
}

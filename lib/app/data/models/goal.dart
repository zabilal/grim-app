// models/goal.dart
class Goal {
  String id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  bool isProfessional;
  double progress;
  List<Milestone> milestones;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isProfessional,
    this.progress = 0.0,
    this.milestones = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isProfessional': isProfessional,
    'progress': progress,
    'milestones': milestones.map((m) => m.toJson()).toList(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    isProfessional: json['isProfessional'],
    progress: json['progress'] ?? 0.0,
    milestones:
        (json['milestones'] as List?)
            ?.map((m) => Milestone.fromJson(m))
            .toList() ??
        [],
  );
}

class Milestone {
  String id;
  String title;
  bool isCompleted;
  DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
  );
}



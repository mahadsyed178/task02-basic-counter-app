// lib/models/task_model.dart

class Task {
  final String id;
  String title;
  bool isDone;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  // Convert Task to JSON string for SharedPreferences storage
  String toJson() {
    return '{"id":"$id","title":"${title.replaceAll('"', '\\"')}","isDone":$isDone,"createdAt":"${createdAt.toIso8601String()}"}';
  }

  // Create Task from JSON string retrieved from SharedPreferences
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
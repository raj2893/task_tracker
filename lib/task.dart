class Task {
  String id; // Add the id property
  String name;
  bool isCompleted;
  DateTime? deadline;

  Task({
    required this.id,
    required this.name,
    required this.isCompleted,
    this.deadline,
  });

  // Convert Task object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
    };
  }
}

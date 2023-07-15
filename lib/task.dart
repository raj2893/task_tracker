class Task {
  String id; // Add the id property
  String name;
  bool isCompleted;

  Task({required this.id, required this.name, required this.isCompleted});

  // Convert Task object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
    };
  }
}

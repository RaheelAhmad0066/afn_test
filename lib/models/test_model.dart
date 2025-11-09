class TestModel {
  final String id;
  final String topicId;
  final String name;
  final int questionCount;
  final DateTime createdAt;

  TestModel({
    required this.id,
    required this.topicId,
    required this.name,
    this.questionCount = 0,
    required this.createdAt,
  });

  // Add copyWith method
  TestModel copyWith({
    String? id,
    String? topicId,
    String? name,
    int? questionCount,
    DateTime? createdAt,
  }) {
    return TestModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'name': name,
      'questionCount': questionCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] ?? '',
      topicId: json['topicId'] ?? '',
      name: json['name'] ?? '',
      questionCount: json['questionCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
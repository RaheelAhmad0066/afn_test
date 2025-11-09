class TopicModel {
  final String id;
  final String name;
  final String category;
  final DateTime createdAt;
  final int testCount;

  TopicModel({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    this.testCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'testCount': testCount,
    };
  }

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      testCount: json['testCount'] ?? 0,
    );
  }

  TopicModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? createdAt,
    int? testCount,
  }) {
    return TopicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      testCount: testCount ?? this.testCount,
    );
  }
}
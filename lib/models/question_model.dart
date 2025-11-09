class QuestionModel {
  final String id;
  final String testId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuestionModel({
    required this.id,
    required this.testId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      testId: json['testId'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'],
    );
  }

  QuestionModel copyWith({
    String? id,
    String? testId,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}
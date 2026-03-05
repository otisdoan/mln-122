class QuizResult {
  final String id;
  final String userId;
  final int score;
  final int totalQuestions;
  final Duration timeTaken;
  final DateTime createdAt;
  final String? setId;

  const QuizResult({
    required this.id,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.createdAt,
    this.setId,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      score: json['score'] as int,
      totalQuestions: json['total_questions'] as int,
      timeTaken: Duration(seconds: json['time_taken_seconds'] as int? ?? 0),
      createdAt: DateTime.parse(json['created_at'] as String),
      setId: json['set_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'score': score,
      'total_questions': totalQuestions,
      'time_taken_seconds': timeTaken.inSeconds,
      'set_id': setId,
    };
  }

  double get percentage => totalQuestions > 0 ? score / totalQuestions : 0;
}

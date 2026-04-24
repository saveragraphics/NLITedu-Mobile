class Quiz {
  final String id;
  final String title;
  final String description;
  final String courseSlug;
  final int durationMinutes;
  final bool isActive;
  final DateTime? scheduledFor;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.courseSlug,
    required this.durationMinutes,
    required this.isActive,
    this.scheduledFor,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      courseSlug: json['course_slug'],
      durationMinutes: json['duration_minutes'] ?? 30,
      isActive: json['is_active'] ?? true,
      scheduledFor: json['scheduled_for'] != null ? DateTime.parse(json['scheduled_for']) : null,
    );
  }
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final int points;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.points,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      options: List<String>.from(json['options']),
      correctIndex: json['correct_index'],
      points: json['points'] ?? 1,
    );
  }
}

class QuizAttempt {
  final String id;
  final String userEmail;
  final String quizId;
  final int score;
  final int totalPoints;
  final Map<String, dynamic> answers;

  QuizAttempt({
    required this.id,
    required this.userEmail,
    required this.quizId,
    required this.score,
    required this.totalPoints,
    required this.answers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      userEmail: json['user_email'],
      quizId: json['quiz_id'],
      score: json['score'],
      totalPoints: json['total_points'],
      answers: json['answers'] ?? {},
    );
  }
}

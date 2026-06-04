class LearningGoal {
  final String id;
  final String userEmail;
  final double currentHours;
  final double goalHours;
  final String statusLabel;

  LearningGoal({
    required this.id,
    required this.userEmail,
    required this.currentHours,
    required this.goalHours,
    required this.statusLabel,
  });

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      id: json['id'],
      userEmail: json['user_email'],
      currentHours: (json['current_hours'] as num).toDouble(),
      goalHours: (json['goal_hours'] as num).toDouble(),
      statusLabel: json['status_label'] ?? 'On Track',
    );
  }

  double get progress => (currentHours / goalHours).clamp(0.0, 1.0);
}

class Certification {
  final String id;
  final String title;
  final String issuedDate;
  final String pdfUrl;

  Certification({
    required this.id,
    required this.title,
    required this.issuedDate,
    required this.pdfUrl,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'],
      title: json['course_title'],
      issuedDate: json['issued_date'],
      pdfUrl: json['pdf_url'],
    );
  }
}

class UpcomingSession {
  final String id;
  final String title;
  final String day;
  final String month;
  final String time;
  final String platform;
  final String type;

  UpcomingSession({
    required this.id,
    required this.title,
    required this.day,
    required this.month,
    required this.time,
    required this.platform,
    required this.type,
  });

  factory UpcomingSession.fromJson(Map<String, dynamic> json) {
    return UpcomingSession(
      id: json['id'],
      title: json['course_title'],
      day: json['day'],
      month: json['month'],
      time: json['session_time'],
      platform: json['platform'],
      type: json['type'] ?? 'Live Class',
    );
  }
}

class RecordedSession {
  final String id;
  final String topic;
  final String videoUrl;
  final String recordedAt;
  final String courseTitle;

  RecordedSession({
    required this.id,
    required this.topic,
    required this.videoUrl,
    required this.recordedAt,
    required this.courseTitle,
  });

  factory RecordedSession.fromJson(Map<String, dynamic> json) {
    return RecordedSession(
      id: json['id'],
      topic: json['topic'],
      videoUrl: json['video_url'],
      recordedAt: json['recorded_at'],
      courseTitle: json['course_title'],
    );
  }
}

class StudyMaterial {
  final String id;
  final String topic;
  final String documentUrl;
  final String createdAt;
  final String courseTitle;

  StudyMaterial({
    required this.id,
    required this.topic,
    required this.documentUrl,
    required this.createdAt,
    required this.courseTitle,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'],
      topic: json['topic'],
      documentUrl: json['document_url'],
      createdAt: json['created_at'],
      courseTitle: json['course_title'],
    );
  }
}

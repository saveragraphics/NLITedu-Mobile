class LiveSession {
  final String id;
  final String courseId;
  final String courseTitle;
  final String sessionUrl;
  final bool isLive;
  final DateTime startedAt;

  LiveSession({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.sessionUrl,
    required this.isLive,
    required this.startedAt,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'],
      courseId: json['course_id'],
      courseTitle: json['course_title'] ?? json['course_id'],
      sessionUrl: json['session_url'],
      isLive: json['is_live'] ?? false,
      startedAt: DateTime.parse(json['started_at']),
    );
  }
}

class LiveAttendance {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final DateTime joinedAt;

  LiveAttendance({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
    };
  }
}

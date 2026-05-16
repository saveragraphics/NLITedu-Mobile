class RecordedSession {
  final String id;
  final String courseId;
  final String courseTitle;
  final String topic;
  final String videoUrl;
  final DateTime recordedAt;

  RecordedSession({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.topic,
    required this.videoUrl,
    required this.recordedAt,
  });

  factory RecordedSession.fromJson(Map<String, dynamic> json) {
    return RecordedSession(
      id: json['id'],
      courseId: json['course_id'],
      courseTitle: json['course_title'] ?? json['course_id'],
      topic: json['topic'] ?? 'Untitled Session',
      videoUrl: json['video_url'],
      recordedAt: json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : DateTime.now(),
    );
  }
}

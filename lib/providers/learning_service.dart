import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_models.dart';
import '../models/quiz_models.dart';

class LearningService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch user's certificates
  Future<List<Certification>> fetchCertificates() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('certificates')
          .select()
          .eq('user_email', user.email!);
      
      return (response as List).map((json) => Certification.fromJson(json)).toList();
    } catch (e) {
      // If the table doesn't exist or there's an error, return empty list to show empty state
      return [];
    }
  }

  /// Fetch user's weekly goal
  Future<LearningGoal> fetchWeeklyGoal() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final response = await _supabase
        .from('learning_goals')
        .select()
        .eq('user_email', user.email!)
        .maybeSingle();
    
    if (response == null) {
      // Create default goal if none exists
      final newGoal = {
        'user_email': user.email,
        'current_hours': 0.0,
        'goal_hours': 5.0,
        'status_label': 'On Track'
      };
      final created = await _supabase.from('learning_goals').insert(newGoal).select().single();
      return LearningGoal.fromJson(created);
    }
    
    return LearningGoal.fromJson(response);
  }

  /// Update user's weekly goal hours
  Future<void> updateWeeklyGoalHours(double goalHours) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final existing = await _supabase
        .from('learning_goals')
        .select()
        .eq('user_email', user.email!)
        .maybeSingle();

    final statusLabel = 'On Track';
    if (existing == null) {
      await _supabase.from('learning_goals').insert({
        'user_email': user.email!,
        'current_hours': 0.0,
        'goal_hours': goalHours,
        'status_label': statusLabel,
      });
    } else {
      await _supabase.from('learning_goals').update({
        'goal_hours': goalHours,
        'status_label': statusLabel,
      }).eq('user_email', user.email!);
    }
  }

  /// Fetch upcoming sessions
  Future<List<UpcomingSession>> fetchUpcomingSessions() async {
    final response = await _supabase
        .from('scheduled_sessions')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => UpcomingSession.fromJson(json)).toList();
  }

  /// Log session attendance (Option A: Auto-tracking)
  Future<String> startSessionSession(String sessionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return "";

    final response = await _supabase.from('live_attendance_logs').insert({
      'session_id': sessionId,
      'student_email': user.email,
      'joined_at': DateTime.now().toIso8601String(),
    }).select().single();
    
    return response['id'];
  }

  Future<void> endSessionSession(String logId) async {
    final now = DateTime.now();
    
    // 1. Get joined_at
    final log = await _supabase.from('live_attendance_logs').select('joined_at').eq('id', logId).single();
    final joinedAt = DateTime.parse(log['joined_at']);
    final durationMinutes = now.difference(joinedAt).inMinutes;

    // 2. Update log
    await _supabase.from('live_attendance_logs').update({
      'left_at': now.toIso8601String(),
      'duration_minutes': durationMinutes,
    }).eq('id', logId);

    // 3. Update Weekly Goal (Convert minutes to hours)
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final hoursToAdd = durationMinutes / 60.0;
      final currentGoal = await fetchWeeklyGoal();
      
      await _supabase.from('learning_goals').update({
        'current_hours': currentGoal.currentHours + hoursToAdd,
        'last_updated': now.toIso8601String(),
      }).eq('user_email', user.email!);
    }
  }

  /// Fetch recorded sessions for a specific course
  Future<List<RecordedSession>> fetchRecordedSessionsByCourse(String courseTitle) async {
    final response = await _supabase
        .from('recorded_sessions')
        .select()
        .eq('course_title', courseTitle)
        .order('recorded_at', ascending: false);
    
    return (response as List).map((json) => RecordedSession.fromJson(json)).toList();
  }

  /// Fetch study materials for a specific course
  Future<List<StudyMaterial>> fetchStudyMaterialsByCourse(String courseTitle) async {
    final response = await _supabase
        .from('study_materials')
        .select()
        .eq('course_title', courseTitle)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => StudyMaterial.fromJson(json)).toList();
  }
}

final learningServiceProvider = Provider((ref) => LearningService());

final certificatesProvider = FutureProvider<List<Certification>>((ref) {
  return ref.watch(learningServiceProvider).fetchCertificates();
});

final weeklyGoalProvider = FutureProvider<LearningGoal>((ref) {
  return ref.watch(learningServiceProvider).fetchWeeklyGoal();
});

final upcomingSessionsProvider = FutureProvider<List<UpcomingSession>>((ref) {
  return ref.watch(learningServiceProvider).fetchUpcomingSessions();
});

final courseRecordingsProvider = FutureProvider.family<List<RecordedSession>, String>((ref, courseTitle) {
  return ref.watch(learningServiceProvider).fetchRecordedSessionsByCourse(courseTitle);
});

// --- Quiz Providers ---

final availableQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('quizzes')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);
  
  return (response as List).map((json) => Quiz.fromJson(json)).toList();
});

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>((ref, quizId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('quiz_questions')
      .select()
      .eq('quiz_id', quizId)
      .order('order_index', ascending: true);
  
  return (response as List).map((json) => QuizQuestion.fromJson(json)).toList();
});

final quizAttemptsProvider = FutureProvider<List<String>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  final response = await supabase
      .from('quiz_attempts')
      .select('quiz_id')
      .eq('user_email', user.email!);
  
  return (response as List).map((json) => json['quiz_id'] as String).toList();
});

final studyMaterialsProvider = FutureProvider.family<List<StudyMaterial>, String>((ref, courseTitle) {
  return ref.watch(learningServiceProvider).fetchStudyMaterialsByCourse(courseTitle);
});

final enrolledStudyMaterialsProvider = FutureProvider<List<StudyMaterial>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  // Get user's enrolled courses
  final enrollmentsResp = await supabase.from('enrollments').select('course_title').eq('user_email', user.email!);
  final enrolledTitles = (enrollmentsResp as List).map((e) => e['course_title'] as String).toList();
  
  if (enrolledTitles.isEmpty) return [];
  
  // Get study materials for those courses
  final materialsResp = await supabase.from('study_materials').select().inFilter('course_title', enrolledTitles).order('created_at', ascending: false);
  return (materialsResp as List).map((json) => StudyMaterial.fromJson(json)).toList();
});

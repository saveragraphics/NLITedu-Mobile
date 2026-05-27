import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_session.dart';
import '../core/utils/supabase_utils.dart';

class LiveService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of active live sessions
  Stream<List<LiveSession>> get activeSessionsStream {
    return retryStreamWithAuth<List<LiveSession>>(() => _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', true)
        .map((maps) => maps.map((m) => LiveSession.fromJson(m)).toList()));
  }

  /// Stream of upcoming scheduled sessions
  Stream<List<LiveSession>> get upcomingSessionsStream {
    return retryStreamWithAuth<List<LiveSession>>(() => _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', false)
        .map((maps) => maps
            .map((m) => LiveSession.fromJson(m))
            .where((s) => s.scheduledAt != null && s.scheduledAt!.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
            .toList()));
  }

  /// Log student attendance
  Future<void> logAttendance(LiveSession session) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final name = user.userMetadata?['full_name'] ?? 'Student';
    
    await _supabase.from('live_attendance').insert({
      'session_id': session.id,
      'student_id': user.id,
      'student_name': name,
      'student_email': user.email,
    });
  }
}

final liveServiceProvider = Provider((ref) => LiveService());

/// Provider for active live sessions matching user's enrollment
final activeLiveSessionsProvider = StreamProvider<List<LiveSession>>((ref) {
  final service = ref.watch(liveServiceProvider);
  return service.activeSessionsStream;
});

/// Provider for upcoming scheduled sessions
final upcomingLiveSessionsProvider = StreamProvider<List<LiveSession>>((ref) {
  final service = ref.watch(liveServiceProvider);
  return service.upcomingSessionsStream;
});

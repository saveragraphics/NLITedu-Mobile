import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/notification_service.dart';
import '../models/live_session.dart';
import '../models/quiz_models.dart';
import '../core/utils/supabase_utils.dart';

/// Notification preference keys
class NotificationPrefs {
  static const String liveAlerts = 'pref_live_alerts';
  static const String scheduledReminders = 'pref_scheduled_reminders';
  static const String quizReminders = 'pref_quiz_reminders';
  static const String pushEnabled = 'pref_push_enabled';

  static Future<bool> isEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true; // Default ON
  }

  static Future<void> setEnabled(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

/// Provider that actively listens to Supabase streams and triggers notifications.
/// This is initialized once and stays alive for the app lifecycle.
class NotificationWatcher {
  final NotificationService _notifService;
  final SupabaseClient _supabase;
  
  StreamSubscription? _liveSubscription;
  StreamSubscription? _upcomingSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _materialsSubscription;
  
  // Track which sessions we've already notified about to avoid duplicates
  final Set<String> _notifiedLiveSessions = {};
  final Set<String> _scheduledReminders = {};
  final Set<String> _notifiedMaterials = {};

  static const String _notifiedLiveKey = 'notified_live_sessions';
  static const String _scheduledRemindersKey = 'scheduled_reminders_sessions';
  static const String _notifiedMaterialsKey = 'notified_materials';

  NotificationWatcher(this._notifService, this._supabase) {
    // Watch auth changes to dynamically start and stop watching
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        startWatching();
      } else {
        dispose();
      }
    });
  }

  /// Start watching for notification-worthy events
  Future<void> startWatching() async {
    await _notifService.initialize();
    
    // Load previously notified sessions from preferences
    final prefs = await SharedPreferences.getInstance();
    _notifiedLiveSessions.addAll(prefs.getStringList(_notifiedLiveKey) ?? []);
    _scheduledReminders.addAll(prefs.getStringList(_scheduledRemindersKey) ?? []);
    _notifiedMaterials.addAll(prefs.getStringList(_notifiedMaterialsKey) ?? []);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Cancel existing subscriptions to avoid duplicates
    await _liveSubscription?.cancel();
    await _upcomingSubscription?.cancel();
    await _materialsSubscription?.cancel();
    _liveSubscription = null;
    _upcomingSubscription = null;
    _materialsSubscription = null;

    // Helper to check dynamic enrollment
    Future<bool> checkUserEnrollment(String courseTitle) async {
      try {
        final enrollments = await _supabase
            .from('enrollments')
            .select('course_title')
            .eq('email', user.email ?? user.phone ?? '');
        
        final enrolledTitles = (enrollments as List)
            .map((e) => (e['course_title'] as String).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase())
            .toSet();

        final sessionTitleClean = courseTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        
        return enrolledTitles.any((et) => sessionTitleClean.contains(et) || et.contains(sessionTitleClean));
      } catch (e) {
        print('Error verifying dynamic enrollment: $e');
        return false;
      }
    }

    // Watch live sessions for instant notifications
    _liveSubscription = retryStreamWithAuth<List<Map<String, dynamic>>>(() => _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', true))
        .listen((rows) async {
      final isLiveEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.liveAlerts);
      final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
      if (!isLiveEnabled || !isPushEnabled) return;

      for (final row in rows) {
        final session = LiveSession.fromJson(row);
        
        // Dynamically verify enrollment for this session
        final isEnrolled = await checkUserEnrollment(session.courseTitle);
        
        // Only notify for enrolled courses, and only once per session
        if (isEnrolled && !_notifiedLiveSessions.contains(session.id)) {
          _notifiedLiveSessions.add(session.id);
          await prefs.setStringList(_notifiedLiveKey, _notifiedLiveSessions.toList());
          await _notifService.showLiveClassNotification(session);
        }
      }
    });

    // Watch upcoming sessions for scheduled reminders
    _upcomingSubscription = retryStreamWithAuth<List<Map<String, dynamic>>>(() => _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', false))
        .listen((rows) async {
      final isScheduledEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.scheduledReminders);
      final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
      if (!isScheduledEnabled || !isPushEnabled) return;

      for (final row in rows) {
        final session = LiveSession.fromJson(row);
        
        // Dynamically verify enrollment for this session
        final isEnrolled = await checkUserEnrollment(session.courseTitle);
        
        if (isEnrolled && 
            session.scheduledAt != null && 
            !_scheduledReminders.contains(session.id)) {
          // Only schedule if in the future
          if (session.scheduledAt!.isAfter(DateTime.now())) {
            _scheduledReminders.add(session.id);
            await prefs.setStringList(_scheduledRemindersKey, _scheduledReminders.toList());
            
            // Show immediate notification
            await _notifService.showNewScheduledClassNotification(session);
            
            // Schedule the reminder for 15 mins before
            await _notifService.scheduleClassReminder(session);
          }
        }
      }
    });

    // Watch new study materials
    _materialsSubscription = retryStreamWithAuth<List<Map<String, dynamic>>>(() => _supabase
        .from('study_materials')
        .stream(primaryKey: ['id']))
        .listen((rows) async {
      final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
      if (!isPushEnabled) return;

      // Ensure we only notify for newly added materials, not old ones on first load
      final now = DateTime.now();

      for (final row in rows) {
        final materialId = row['id'].toString();
        final courseTitle = row['course_title'] as String;
        final topic = row['topic'] as String;
        final createdAtStr = row['created_at'] as String?;
        
        if (createdAtStr == null) continue;
        
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null) continue;
        
        // Skip notifying if the material is older than 24 hours (prevents flood on first load)
        if (now.difference(createdAt).inHours > 24) {
          if (!_notifiedMaterials.contains(materialId)) {
            _notifiedMaterials.add(materialId);
            await prefs.setStringList(_notifiedMaterialsKey, _notifiedMaterials.toList());
          }
          continue;
        }

        final isEnrolled = await checkUserEnrollment(courseTitle);
        
        if (isEnrolled && !_notifiedMaterials.contains(materialId)) {
          _notifiedMaterials.add(materialId);
          await prefs.setStringList(_notifiedMaterialsKey, _notifiedMaterials.toList());
          await _notifService.showNewMaterialNotification(id: materialId, courseTitle: courseTitle, topic: topic);
        }
      }
    });

    // Fetch and schedule quiz reminders
    try {
      final enrollments = await _supabase
          .from('enrollments')
          .select('course_title')
          .eq('email', user.email ?? user.phone ?? '');
      final enrolledTitles = (enrollments as List)
          .map((e) => (e['course_title'] as String).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase())
          .toSet();
      await _scheduleQuizReminders(enrolledTitles);
    } catch (e) {
      print('Initial quiz reminder fetch skipped: $e');
    }
  }

  /// Fetch upcoming quizzes and schedule reminders
  Future<void> _scheduleQuizReminders(Set<String> enrolledTitles) async {
    final isQuizEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.quizReminders);
    final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
    if (!isQuizEnabled || !isPushEnabled) return;

    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('is_active', true);

      final quizzes = (response as List)
          .map((q) => Quiz.fromJson(q))
          .where((q) => q.scheduledFor != null && q.scheduledFor!.isAfter(DateTime.now()))
          .toList();

      for (final quiz in quizzes) {
        final quizSlugClean = quiz.courseSlug.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        // Check if the quiz belongs to an enrolled course
        final isEnrolled = enrolledTitles.any((et) => quizSlugClean.contains(et) || et.contains(quizSlugClean));
        if (isEnrolled) {
          await _notifService.scheduleQuizReminder(quiz);
        }
      }
    } catch (e) {
      // Quiz table might not exist yet — silently ignore
      print('Quiz reminder scheduling skipped: $e');
    }
  }

  /// Stop all watchers
  void dispose() {
    _liveSubscription?.cancel();
    _upcomingSubscription?.cancel();
    _materialsSubscription?.cancel();
    _authSubscription?.cancel();
  }
}

/// Riverpod provider for the notification watcher
final notificationWatcherProvider = Provider<NotificationWatcher>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  final supabase = Supabase.instance.client;
  final watcher = NotificationWatcher(notifService, supabase);
  
  ref.onDispose(() => watcher.dispose());
  
  return watcher;
});

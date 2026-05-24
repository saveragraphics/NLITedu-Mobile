import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/notification_service.dart';
import '../models/live_session.dart';
import '../models/quiz_models.dart';
import 'live_provider.dart';
import 'enrollment_service.dart';

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
  
  // Track which sessions we've already notified about to avoid duplicates
  final Set<String> _notifiedLiveSessions = {};
  final Set<String> _scheduledReminders = {};

  static const String _notifiedLiveKey = 'notified_live_sessions';
  static const String _scheduledRemindersKey = 'scheduled_reminders_sessions';

  NotificationWatcher(this._notifService, this._supabase);

  /// Start watching for notification-worthy events
  Future<void> startWatching() async {
    await _notifService.initialize();
    
    // Load previously notified sessions from preferences
    final prefs = await SharedPreferences.getInstance();
    _notifiedLiveSessions.addAll(prefs.getStringList(_notifiedLiveKey) ?? []);
    _scheduledReminders.addAll(prefs.getStringList(_scheduledRemindersKey) ?? []);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Get user's enrolled course titles
    final enrollments = await _supabase
        .from('enrollments')
        .select('course_title')
        .eq('email', user.email ?? user.phone ?? '');
    
    final enrolledTitles = (enrollments as List)
        .map((e) => (e['course_title'] as String).trim().toLowerCase())
        .toSet();

    if (enrolledTitles.isEmpty) return;

    // Watch live sessions for instant notifications
    _liveSubscription = _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', true)
        .listen((rows) async {
      final isLiveEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.liveAlerts);
      final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
      if (!isLiveEnabled || !isPushEnabled) return;

      for (final row in rows) {
        final session = LiveSession.fromJson(row);
        final titleLower = session.courseTitle.trim().toLowerCase();
        
        // Only notify for enrolled courses, and only once per session
        if (enrolledTitles.contains(titleLower) && !_notifiedLiveSessions.contains(session.id)) {
          _notifiedLiveSessions.add(session.id);
          prefs.setStringList(_notifiedLiveKey, _notifiedLiveSessions.toList());
          await _notifService.showLiveClassNotification(session);
        }
      }
    });

    // Watch upcoming sessions for scheduled reminders
    _upcomingSubscription = _supabase
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('is_live', false)
        .listen((rows) async {
      final isScheduledEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.scheduledReminders);
      final isPushEnabled = await NotificationPrefs.isEnabled(NotificationPrefs.pushEnabled);
      if (!isScheduledEnabled || !isPushEnabled) return;

      for (final row in rows) {
        final session = LiveSession.fromJson(row);
        final titleLower = session.courseTitle.trim().toLowerCase();
        
        if (enrolledTitles.contains(titleLower) && 
            session.scheduledAt != null && 
            !_scheduledReminders.contains(session.id)) {
          // Only schedule if in the future
          if (session.scheduledAt!.isAfter(DateTime.now())) {
            _scheduledReminders.add(session.id);
            prefs.setStringList(_scheduledRemindersKey, _scheduledReminders.toList());
            
            // Show immediate notification
            await _notifService.showNewScheduledClassNotification(session);
            
            // Schedule the reminder for 15 mins before
            await _notifService.scheduleClassReminder(session);
          }
        }
      }
    });

    // Fetch and schedule quiz reminders
    await _scheduleQuizReminders(enrolledTitles);
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
        // Check if the quiz belongs to an enrolled course
        if (enrolledTitles.any((t) => quiz.courseSlug.toLowerCase().contains(t) || 
            t.contains(quiz.courseSlug.toLowerCase()))) {
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/live_session.dart';
import '../models/quiz_models.dart';

/// Global navigator key for notification tap navigation
final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

/// Central notification service for NLIT app.
/// Handles local push notifications for live classes, scheduled classes, and quizzes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification channel IDs
  static const String _liveChannelId = 'nlit_live_class';
  static const String _scheduledChannelId = 'nlit_scheduled_class';
  static const String _quizChannelId = 'nlit_quiz_exam';

  // Notification ID ranges to avoid collision
  static const int _liveBaseId = 1000;
  static const int _scheduledBaseId = 2000;
  static const int _quizBaseId = 3000;

  // SharedPreferences keys for notification history
  static const String _historyKey = 'notification_history';
  static const String _unreadCountKey = 'notification_unread_count';

  /// Initialize the notification plugin with Android configuration
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _liveChannelId, 'Live Class Alerts',
          description: 'Notifications when a live class starts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _scheduledChannelId, 'Scheduled Class Reminders',
          description: 'Reminders for upcoming scheduled classes',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _quizChannelId, 'Quiz & Exam Reminders',
          description: 'Reminders for upcoming quizzes and exams',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }

    _initialized = true;
  }

  /// Request notification permission on Android 13+
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Show an immediate notification when a live class starts
  Future<void> showLiveClassNotification(LiveSession session) async {
    final id = _liveBaseId + session.id.hashCode.abs() % 999;

    await _plugin.show(
      id,
      '🔴 LIVE NOW: ${session.courseTitle}',
      'Your class is live! Tap to join now.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _liveChannelId, 'Live Class Alerts',
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFFEF4444),
          colorized: true,
          category: AndroidNotificationCategory.event,
          visibility: NotificationVisibility.public,
          ticker: 'Live class started: ${session.courseTitle}',
          styleInformation: BigTextStyleInformation(
            'Your enrolled class "${session.courseTitle}" is now live! Tap to join the session immediately.',
            contentTitle: '🔴 LIVE NOW: ${session.courseTitle}',
          ),
        ),
      ),
      payload: 'live:${session.id}',
    );

    await _saveNotificationToHistory(
      title: '🔴 LIVE: ${session.courseTitle}',
      body: 'Class went live',
      type: 'live',
      courseId: session.courseId,
    );
  }

  /// Schedule a reminder notification before a scheduled class
  Future<void> scheduleClassReminder(LiveSession session, {int minutesBefore = 15}) async {
    if (session.scheduledAt == null) return;
    
    final scheduledTime = session.scheduledAt!.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return; // Already past

    final id = _scheduledBaseId + session.id.hashCode.abs() % 999;
    final diff = scheduledTime.difference(DateTime.now());

    // Use a delayed show instead of zonedSchedule for simplicity
    Future.delayed(diff, () async {
      await _plugin.show(
        id,
        '📅 Class in $minutesBefore min: ${session.courseTitle}',
        'Your scheduled class starts at ${_formatTime(session.scheduledAt!)}. Get ready!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _scheduledChannelId, 'Scheduled Class Reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF3B82F6),
            colorized: true,
            category: AndroidNotificationCategory.reminder,
            styleInformation: BigTextStyleInformation(
              'Your class "${session.courseTitle}" starts at ${_formatTime(session.scheduledAt!)}. Tap to view details.',
              contentTitle: '📅 Class in $minutesBefore min',
            ),
          ),
        ),
        payload: 'scheduled:${session.id}',
      );

      await _saveNotificationToHistory(
        title: '📅 ${session.courseTitle}',
        body: 'Class starts at ${_formatTime(session.scheduledAt!)}',
        type: 'scheduled',
        courseId: session.courseId,
      );
    });
  }

  /// Schedule a reminder notification before a quiz/exam
  Future<void> scheduleQuizReminder(Quiz quiz, {int minutesBefore = 30}) async {
    if (quiz.scheduledFor == null) return;
    
    final scheduledTime = quiz.scheduledFor!.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    final id = _quizBaseId + quiz.id.hashCode.abs() % 999;
    final diff = scheduledTime.difference(DateTime.now());

    Future.delayed(diff, () async {
      await _plugin.show(
        id,
        '📝 Exam in $minutesBefore min: ${quiz.title}',
        'Your ${quiz.durationMinutes}-minute exam starts soon. Be prepared!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _quizChannelId, 'Quiz & Exam Reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF8B5CF6),
            colorized: true,
            category: AndroidNotificationCategory.reminder,
            styleInformation: BigTextStyleInformation(
              '"${quiz.title}" starts at ${_formatTime(quiz.scheduledFor!)}. Duration: ${quiz.durationMinutes} minutes.',
              contentTitle: '📝 Exam in $minutesBefore min',
            ),
          ),
        ),
        payload: 'quiz:${quiz.id}',
      );

      await _saveNotificationToHistory(
        title: '📝 ${quiz.title}',
        body: 'Exam starts at ${_formatTime(quiz.scheduledFor!)}',
        type: 'quiz',
        courseId: quiz.courseSlug,
      );
    });
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Payload format: "type:id"
    // Navigation is handled by the NotificationProvider watching these
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Save notification to local history for the notification center
  Future<void> _saveNotificationToHistory({
    required String title,
    required String body,
    required String type,
    required String courseId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    final timestamp = DateTime.now().toIso8601String();
    
    // Format: title|body|type|courseId|timestamp
    history.insert(0, '$title|$body|$type|$courseId|$timestamp');
    
    // Keep only last 50 notifications
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    await prefs.setStringList(_historyKey, history);
    
    // Increment unread count
    final unread = prefs.getInt(_unreadCountKey) ?? 0;
    await prefs.setInt(_unreadCountKey, unread + 1);
  }

  /// Get notification history for the notification center
  Future<List<NotificationItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    
    return history.map((entry) {
      final parts = entry.split('|');
      if (parts.length < 5) return null;
      return NotificationItem(
        title: parts[0],
        body: parts[1],
        type: parts[2],
        courseId: parts[3],
        timestamp: DateTime.tryParse(parts[4]) ?? DateTime.now(),
      );
    }).whereType<NotificationItem>().toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unreadCountKey) ?? 0;
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unreadCountKey, 0);
  }

  /// Clear all notification history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.setInt(_unreadCountKey, 0);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

/// Simple notification item model for the notification center
class NotificationItem {
  final String title;
  final String body;
  final String type; // 'live', 'scheduled', 'quiz'
  final String courseId;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.type,
    required this.courseId,
    required this.timestamp,
  });

  Color get color {
    switch (type) {
      case 'live': return const Color(0xFFEF4444);
      case 'scheduled': return const Color(0xFF3B82F6);
      case 'quiz': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF6B7280);
    }
  }

  String get label {
    switch (type) {
      case 'live': return 'LIVE CLASS';
      case 'scheduled': return 'SCHEDULED';
      case 'quiz': return 'QUIZ/EXAM';
      default: return 'NOTIFICATION';
    }
  }
}

/// Riverpod provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  return NotificationService().getUnreadCount();
});

/// Provider for notification history
final notificationHistoryProvider = FutureProvider<List<NotificationItem>>((ref) async {
  return NotificationService().getHistory();
});

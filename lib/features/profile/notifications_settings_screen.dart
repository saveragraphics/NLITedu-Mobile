import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../providers/notification_provider.dart';

/// Notification Settings — persisted toggles that control actual notification behavior
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushEnabled = true;
  bool _liveAlerts = true;
  bool _scheduledReminders = true;
  bool _quizReminders = true;
  bool _newCourses = false;
  bool _weeklyDigest = true;
  bool _promotions = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(NotificationPrefs.pushEnabled) ?? true;
      _liveAlerts = prefs.getBool(NotificationPrefs.liveAlerts) ?? true;
      _scheduledReminders = prefs.getBool(NotificationPrefs.scheduledReminders) ?? true;
      _quizReminders = prefs.getBool(NotificationPrefs.quizReminders) ?? true;
      _newCourses = prefs.getBool('pref_new_courses') ?? false;
      _weeklyDigest = prefs.getBool('pref_weekly_digest') ?? true;
      _promotions = prefs.getBool('pref_promotions') ?? false;
      _loading = false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_loading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface, elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop()),
        title: Text("Notifications", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Master toggle
          Text("General", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _toggleCard(context, LucideIcons.bell, "Push Notifications",
            "Enable or disable all push notifications", _pushEnabled,
            (v) { setState(() => _pushEnabled = v); _savePref(NotificationPrefs.pushEnabled, v); }),
          
          const SizedBox(height: 28),
          Text("Class & Exam Alerts", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _toggleCard(context, LucideIcons.video, "Live Class Alerts",
            "Get notified when your enrolled class goes live", _liveAlerts,
            (v) { setState(() => _liveAlerts = v); _savePref(NotificationPrefs.liveAlerts, v); },
            accentColor: const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          _toggleCard(context, LucideIcons.calendar, "Scheduled Class Reminders",
            "Remind 15 minutes before a scheduled class", _scheduledReminders,
            (v) { setState(() => _scheduledReminders = v); _savePref(NotificationPrefs.scheduledReminders, v); },
            accentColor: const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _toggleCard(context, LucideIcons.clipboardList, "Quiz & Exam Reminders",
            "Remind 30 minutes before a scheduled quiz/exam", _quizReminders,
            (v) { setState(() => _quizReminders = v); _savePref(NotificationPrefs.quizReminders, v); },
            accentColor: const Color(0xFF8B5CF6)),

          const SizedBox(height: 28),
          Text("Content Preferences", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _toggleCard(context, LucideIcons.sparkles, "New Course Alerts",
            "Be the first to know about new courses", _newCourses,
            (v) { setState(() => _newCourses = v); _savePref('pref_new_courses', v); }),
          const SizedBox(height: 8),
          _toggleCard(context, LucideIcons.calendarDays, "Weekly Digest",
            "Summary of your learning progress", _weeklyDigest,
            (v) { setState(() => _weeklyDigest = v); _savePref('pref_weekly_digest', v); }),
          const SizedBox(height: 8),
          _toggleCard(context, LucideIcons.megaphone, "Promotions & Offers",
            "Special discounts and deals", _promotions,
            (v) { setState(() => _promotions = v); _savePref('pref_promotions', v); }),
            
          const SizedBox(height: 32),
          Text("Data & Privacy", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              // Confirm before clearing
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear History?"),
                  content: const Text("This will permanently delete all your notification history. This action cannot be undone."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("Clear All"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await NotificationService().clearHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Notification history cleared"),
                      backgroundColor: theme.colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.trash2, size: 20, color: Colors.red)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Clear Notification History", style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                  const SizedBox(height: 2),
                  Text("Permanently delete all past notifications", style: GoogleFonts.inter(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _toggleCard(BuildContext context, IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged, {Color? accentColor}) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final isDisabled = !_pushEnabled && title != "Push Notifications";
    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ])),
          Switch.adaptive(
            value: value,
            onChanged: isDisabled ? null : onChanged,
            activeColor: color),
        ]),
      ),
    );
  }
}

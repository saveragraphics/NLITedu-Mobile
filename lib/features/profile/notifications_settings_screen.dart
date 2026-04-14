import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';

/// Stitch 01 Notification Settings — fully functional toggles
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _courseUpdates = true;
  bool _newCourses = false;
  bool _weeklyDigest = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop()),
        title: Text("Notifications", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Push Notifications", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _toggleCard(LucideIcons.bell, "Push Notifications",
            "Receive alerts on your device", _pushEnabled,
            (v) => setState(() => _pushEnabled = v)),
          const SizedBox(height: 8),
          _toggleCard(LucideIcons.mail, "Email Notifications",
            "Get updates in your inbox", _emailEnabled,
            (v) => setState(() => _emailEnabled = v)),
          const SizedBox(height: 28),
          Text("Content Preferences", style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _toggleCard(LucideIcons.bookOpen, "Course Updates",
            "Progress reminders and deadlines", _courseUpdates,
            (v) => setState(() => _courseUpdates = v)),
          const SizedBox(height: 8),
          _toggleCard(LucideIcons.sparkles, "New Course Alerts",
            "Be the first to know about new courses", _newCourses,
            (v) => setState(() => _newCourses = v)),
          const SizedBox(height: 8),
          _toggleCard(LucideIcons.calendarDays, "Weekly Digest",
            "Summary of your learning progress", _weeklyDigest,
            (v) => setState(() => _weeklyDigest = v)),
          const SizedBox(height: 8),
          _toggleCard(LucideIcons.megaphone, "Promotions & Offers",
            "Special discounts and deals", _promotions,
            (v) => setState(() => _promotions = v)),
        ]),
      ),
    );
  }

  Widget _toggleCard(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 20, color: AppTheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ])),
        Switch.adaptive(
          value: value, onChanged: onChanged,
          activeColor: AppTheme.primary),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../profile/profile_provider.dart';

/// Stitch 01 My Learning Hub — Active courses, certifications, weekly goal, sessions
class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final shortName = profile?.fullName.split(' ').first ?? "Learner";

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 72, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text("My Learning Hub", style: GoogleFonts.plusJakartaSans(
              fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text("Pick up right where you left off, $shortName.",
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 28),

            // ── Weekly Goal Card (gradient from-primary to-primary-container) ──
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Weekly Goal", style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: "3.2", style: GoogleFonts.plusJakartaSans(
                        fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                      TextSpan(text: " / 5h", style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.white70)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text("On Track", style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.64, minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Just 1.8 hours more to hit your personal weekly milestone.",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Active Courses ──
            _activeCourse(
              title: "Advanced React Patterns & System Design",
              module: "Module 4: Composition vs Inheritance",
              status: "In Progress", statusColor: AppTheme.secondaryContainer,
              progress: 0.75, progressText: "75% Complete", lessons: "12 / 16 Lessons",
              isPrimary: true,
            ),
            const SizedBox(height: 16),
            _activeCourse(
              title: "Applied Machine Learning for Product Managers",
              module: "Module 2: Predictive Modeling Fundamentals",
              status: "Paused", statusColor: AppTheme.surfaceContainerHigh,
              progress: 0.22, progressText: "22% Complete", lessons: "4 / 18 Lessons",
              isPrimary: false,
            ),
            const SizedBox(height: 32),

            // ── Recently Completed ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Recently Completed", style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
              Row(children: [
                Text("View All", style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.primary),
              ]),
            ]),
            const SizedBox(height: 16),
            _certCard("UI/UX Design Masterclass", "Issued on Sep 12, 2023"),
            const SizedBox(height: 12),
            _certCard("Clean Code & TDD", "Issued on Aug 05, 2023"),
            const SizedBox(height: 28),

            // ── Upcoming Sessions ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Upcoming Sessions", style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                  const SizedBox(height: 20),
                  _sessionRow("Oct", "24", "Group Study: ML Ethics", "4:00 PM • Live via Zoom"),
                  const SizedBox(height: 16),
                  _sessionRow("Oct", "27", "1-on-1 Mentorship", "10:30 AM • Video Call"),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary.withOpacity(0.2), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("View Full Calendar", style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCourse({
    required String title, required String module,
    required String status, required Color statusColor,
    required double progress, required String progressText, required String lessons,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(status.toUpperCase(), style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: isPrimary ? AppTheme.secondary : AppTheme.onSurfaceVariant,
                letterSpacing: 1)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(module, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(progressText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant)),
            Text(lessons, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(
                isPrimary ? AppTheme.primary : AppTheme.primary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                foregroundColor: isPrimary ? Colors.white : AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(isPrimary ? "Continue" : "Resume", style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                const Icon(LucideIcons.play, size: 14),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _certCard(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.medal, size: 24, color: AppTheme.secondary),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 4),
          Text(date, style: GoogleFonts.inter(
            fontSize: 12, color: AppTheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
        ])),
        Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.download, size: 18, color: AppTheme.primary)),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.share2, size: 18, color: AppTheme.primary)),
        ]),
      ]),
    );
  }

  Widget _sessionRow(String month, String day, String title, String time) {
    return Row(children: [
      Container(
        width: 48, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(month.toUpperCase(), style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant)),
          Text(day, style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
        const SizedBox(height: 2),
        Text(time, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant)),
      ]),
    ]);
  }
}

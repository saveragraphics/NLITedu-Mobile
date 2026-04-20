import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/course.dart';
import '../../../models/learning_models.dart';
import '../../../core/theme.dart';

class WeeklyGoalCard extends StatelessWidget {
  final LearningGoal goal;
  const WeeklyGoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Weekly Goal", 
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white60)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("${goal.currentHours}", 
                style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(" / ${goal.goalHours}h", 
                style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white60)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(100)),
                child: Text(goal.statusLabel, 
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(100))),
              FractionallySizedBox(
                widthFactor: goal.progress.clamp(0, 1),
                child: Container(height: 8, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("You're doing great! Just ${goal.goalHours - goal.currentHours} hours more to hit your milestone.",
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.white70)),
        ],
      ),
    );
  }
}

class CertificationCard extends StatelessWidget {
  final Certification cert;
  const CertificationCard({super.key, required this.cert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.secondaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(LucideIcons.award, color: AppTheme.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.title, 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                Text("Issued on ${cert.issuedDate}", 
                  style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _smallTextButton(LucideIcons.download, "PDF"),
                    const SizedBox(width: 12),
                    _smallTextButton(LucideIcons.share, "Share"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallTextButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary)),
      ],
    );
  }
}

class UpcomingSessionTile extends StatelessWidget {
  final UpcomingSession session;
  const UpcomingSessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 52, height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(session.month.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(session.day, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("${session.time} • ${session.platform}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InstructorSpotlightCard extends StatelessWidget {
  const InstructorSpotlightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ACADEMIC SPOTLIGHT", 
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/app_logo.png', 
                  width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("NLITedu Official", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text("Expert Academic Team", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("\"Empowering students through accessible, global-standard education and real-time mentorship to build the leaders of tomorrow.\"",
             style: GoogleFonts.inter(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}


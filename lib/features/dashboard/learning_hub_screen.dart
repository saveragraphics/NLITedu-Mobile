import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../profile/profile_provider.dart';
import '../../providers/enrollment_service.dart';
import '../../providers/live_provider.dart';
import '../../providers/learning_service.dart';
import '../../models/live_session.dart';
import '../../models/course.dart';
import '../../models/learning_models.dart';
import 'widgets/learning_hub_widgets.dart';

class LearningHubScreen extends ConsumerStatefulWidget {
  const LearningHubScreen({super.key});

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final enrolledCoursesAsync = ref.watch(enrolledFullCoursesProvider);
    final liveSessionsAsync = ref.watch(activeLiveSessionsProvider);
    
    // --- Actual Data Providers ---
    final goalAsync = ref.watch(weeklyGoalProvider);
    final certsAsync = ref.watch(certificatesProvider);
    final upcomingAsync = ref.watch(upcomingSessionsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyGoalProvider);
          ref.invalidate(certificatesProvider);
          ref.invalidate(upcomingSessionsProvider);
          ref.invalidate(enrolledFullCoursesProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ──── Top Bar ────
            _buildSliverAppBar(profile),

            // ──── Header & Goal ────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("My Learning Hub", style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    Text("Pick up right where you left off, ${profile?.fullName.split(' ').first ?? 'Student'}.", 
                      style: GoogleFonts.inter(fontSize: 16, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
                    const SizedBox(height: 32),
                    
                    // Actual Goal Data
                    goalAsync.when(
                      data: (goal) => WeeklyGoalCard(goal: goal),
                      loading: () => const _LoadingSkeleton(height: 180),
                      error: (_, __) => WeeklyGoalCard(goal: LearningGoal(id: '', userEmail: '', currentHours: 0, goalHours: 5, statusLabel: 'Setup Needed')),
                    ),
                  ],
                ),
              ),
            ),

            // ──── Live Now ────
            liveSessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: _buildLivePriorityCard(context, sessions.first),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ──── Active Courses ────
            _buildShelfHeader("Active Subscriptions"),
            enrolledCoursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) return _buildEmptyState(context);
                final sessions = liveSessionsAsync.value ?? [];
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = courses[index];
                        final session = sessions.cast<LiveSession?>().firstWhere(
                          (s) => s?.courseTitle == course.title, orElse: () => null
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildNexgenCourseCard(context, course, session),
                        );
                      },
                      childCount: courses.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text("Error fetching courses"))),
            ),

            // ──── Certifications ────
            _buildShelfHeader("Recently Completed", actionText: "View All"),
            certsAsync.when(
              data: (certs) {
                if (certs.isEmpty) return _buildNoDataMessage("No certificates earned yet.");
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CertificationCard(cert: certs[index]),
                      ),
                      childCount: certs.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ──── Upcoming Sessions ────
            _buildShelfHeader("Upcoming Sessions"),
            upcomingAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return _buildNoDataMessage("No upcoming sessions scheduled.");
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => UpcomingSessionTile(session: sessions[index]),
                      childCount: sessions.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 40, 24, 120),
              sliver: SliverToBoxAdapter(child: InstructorSpotlightCard()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic profile) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(profile?.avatarUrl ?? "https://i.pravatar.cc/150"),
          ),
          const SizedBox(width: 12),
          Text("Nexgen Learning", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5)),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell, size: 20, color: AppTheme.primary)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildShelfHeader(String title, {String? actionText}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            if (actionText != null) 
              Text(actionText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage(String msg) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildLivePriorityCard(BuildContext context, LiveSession session) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF130F1E),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               _liveBadge(),
               const Spacer(),
               const Icon(LucideIcons.radio, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(session.courseTitle, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 8),
          Text("Join the interactive classroom now.", style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: () => context.push('/live-session', extra: session),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: const Text("Enter Classroom", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return FadeTransition(opacity: _pulseController, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: Text("LIVE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))));
  }

  Widget _buildNexgenCourseCard(BuildContext context, Course course, LiveSession? session) {
    final theme = Theme.of(context);
    final isLive = session != null;
    return GestureDetector(
      onTap: () => context.push('/learning-hub/view', extra: course),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(32), border: Border.all(color: isLive ? Colors.red.withOpacity(0.5) : theme.colorScheme.outlineVariant.withOpacity(0.3), width: isLive ? 2 : 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 10))]),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(course.imageUrl, width: 80, height: 80, fit: BoxFit.cover)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isLive ? Colors.red.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(isLive ? "LIVE NOW" : "IN PROGRESS", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: isLive ? Colors.red : theme.colorScheme.primary))),
                      const SizedBox(height: 8),
                      Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text("Module 4: Advanced Systems", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("75% Complete", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)), Text("12 / 16 Lessons", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey))]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: 0.75, minHeight: 6, backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3), valueColor: AlwaysStoppedAnimation(isLive ? Colors.red : theme.colorScheme.primary))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => context.push('/learning-hub/view', extra: course), style: ElevatedButton.styleFrom(backgroundColor: isLive ? Colors.red : theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(isLive ? "Join Class" : "Continue Learning", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(LucideIcons.play, size: 14)]))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(hasScrollBody: false, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(LucideIcons.bookOpen, size: 64, color: Colors.grey), const SizedBox(height: 24), Text("No active enrollments", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 32), ElevatedButton(onPressed: () => context.go('/discover'), child: const Text("Explore Courses"))])));
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final double height;
  const _LoadingSkeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(height: height, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(32)));
  }
}

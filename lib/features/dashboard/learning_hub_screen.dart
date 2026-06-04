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
import '../../models/quiz_models.dart';
import 'widgets/learning_hub_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final quizzesAsync = ref.watch(availableQuizzesProvider);
    final quizAttemptsAsync = ref.watch(quizAttemptsProvider);
    final attemptedQuizIds = quizAttemptsAsync.value ?? [];
    final studyMaterialsAsync = ref.watch(enrolledStudyMaterialsProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyGoalProvider);
          ref.invalidate(certificatesProvider);
          ref.invalidate(upcomingSessionsProvider);
          ref.invalidate(enrolledFullCoursesProvider);
          ref.invalidate(availableQuizzesProvider);
          ref.invalidate(quizAttemptsProvider);
          ref.invalidate(userEnrollmentsProvider);
          ref.invalidate(enrolledStudyMaterialsProvider);
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
                      data: (goal) => GestureDetector(
                        onTap: () => _showGoalSetupDialog(context, goal),
                        child: WeeklyGoalCard(goal: goal),
                      ),
                      loading: () => const _LoadingSkeleton(height: 180),
                      error: (_, __) => GestureDetector(
                        onTap: () => _showGoalSetupDialog(context, LearningGoal(id: '', userEmail: '', currentHours: 0, goalHours: 5, statusLabel: 'Setup Needed')),
                        child: WeeklyGoalCard(goal: LearningGoal(id: '', userEmail: '', currentHours: 0, goalHours: 5, statusLabel: 'Setup Needed')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ──── Live Now ────
            liveSessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                
                final courses = enrolledCoursesAsync.value ?? [];
                String? imageUrl;
                try {
                  imageUrl = courses.firstWhere((c) => c.title == sessions.first.courseTitle).imageUrl;
                } catch (_) {}

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: _buildLivePriorityCard(context, sessions.first, imageUrl),
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
                        
                        // Extract enrollment status
                        final enrollments = ref.read(userEnrollmentsProvider).value ?? [];
                        final enrollmentMap = enrollments.firstWhere(
                          (e) {
                            final eTitle = (e['course_title'] as String).trim().toLowerCase();
                            final cTitle = course.title.trim().toLowerCase();
                            if (course.slug == 'general' && eTitle == 'nlit course enrollment') {
                              return true;
                            }
                            return eTitle == cTitle;
                          },
                          orElse: () => <String, dynamic>{},
                        );
                        final status = enrollmentMap['status'] as String? ?? 'PAID';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildNexgenCourseCard(context, course, session, enrollmentMap),
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


            // ──── Tests & Assessments ────
            _buildShelfHeader("Tests & Assessments"),
            quizzesAsync.when(
              data: (quizzes) {
                if (quizzes.isEmpty) return _buildNoDataMessage("No active tests available.");
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildQuizCard(context, quizzes[index], attemptedQuizIds),
                      ),
                      childCount: quizzes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: _LoadingSkeleton(height: 100),
                )
              ),
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
          Expanded(
            child: Text("Nexgen Learning Institute Of Technology", style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  Widget _buildLivePriorityCard(BuildContext context, LiveSession session, String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(28),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF130F1E),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
        image: imageUrl != null 
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               _liveBadge(),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.black45,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Row(
                   children: [
                     const Icon(LucideIcons.monitorPlay, color: Colors.white, size: 14),
                     const SizedBox(width: 6),
                     Text("HD Preview", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                   ],
                 ),
               ),
            ],
          ),
          const SizedBox(height: 20),
          Text(session.courseTitle, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 8),
          Text("Join the interactive classroom now.", style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
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

  Widget _buildNexgenCourseCard(BuildContext context, Course course, LiveSession? session, Map<String, dynamic> enrollmentMap) {
    final theme = Theme.of(context);
    final isLive = session != null;
    final isPending = false;
    
    final statusColor = isPending
        ? Colors.amber.shade900
        : (isLive ? Colors.red : theme.colorScheme.primary);
    final statusBgColor = isPending
        ? Colors.amber.withOpacity(0.1)
        : (isLive ? Colors.red.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1));
    final statusText = isPending
        ? "PENDING VERIFICATION"
        : (isLive ? "LIVE NOW" : "ACTIVE / ENROLLED");
    
    final duration = enrollmentMap['duration'] as String? ?? "4 Weeks";

    final progressValue = isPending ? 0.0 : 0.75;
    final progressText = isPending ? "0% Complete" : "75% Complete";
    final lessonsText = isPending ? "0 / 16 Lessons" : "12 / 16 Lessons";
    final buttonText = isPending
        ? "Pending Verification"
        : (isLive ? "Join Class" : "Continue Learning");
    
    return GestureDetector(
      onTap: isPending
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Your enrollment is pending admin verification. Please wait."),
                  backgroundColor: Colors.amber,
                ),
              );
            }
          : () => context.push('/learning-hub/view', extra: course),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(32), border: Border.all(color: isPending ? Colors.amber.withOpacity(0.5) : (isLive ? Colors.red.withOpacity(0.5) : theme.colorScheme.outlineVariant.withOpacity(0.3)), width: (isLive || isPending) ? 2 : 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 10))]),
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
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)), child: Text(statusText, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor))),
                      const SizedBox(height: 8),
                      Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text("Duration: $duration", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(progressText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)), Text(lessonsText, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey))]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progressValue, minHeight: 6, backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3), valueColor: AlwaysStoppedAnimation(isPending ? Colors.amber : (isLive ? Colors.red : theme.colorScheme.primary)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isPending ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Your enrollment is pending admin verification. Please wait."),
                  backgroundColor: Colors.amber,
                ),
              );
            } : () => context.push('/learning-hub/view', extra: course), style: ElevatedButton.styleFrom(backgroundColor: isPending ? Colors.amber.shade700 : (isLive ? Colors.red : theme.colorScheme.primary), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(isPending ? LucideIcons.alertTriangle : LucideIcons.play, size: 14)]))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(hasScrollBody: false, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(LucideIcons.bookOpen, size: 64, color: Colors.grey), const SizedBox(height: 24), Text("No active enrollments", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 32), ElevatedButton(onPressed: () => context.go('/discover'), child: const Text("Explore Courses"))])));
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz, List<String> attemptedQuizIds) {
    final theme = Theme.of(context);
    final isScheduledFuture = quiz.scheduledFor != null && quiz.scheduledFor!.isAfter(DateTime.now());
    final hasAttempted = attemptedQuizIds.contains(quiz.id);
    
    return GestureDetector(
      onTap: () {
        if (isScheduledFuture) return;
        if (hasAttempted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already appeared for this test.'),
              backgroundColor: Colors.amber,
            ),
          );
          return;
        }
        context.push('/quiz', extra: quiz);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withOpacity(isScheduledFuture ? 0.1 : 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isScheduledFuture ? Colors.grey.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.clipboardList, color: isScheduledFuture ? Colors.grey : AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: isScheduledFuture ? Colors.grey : null)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${quiz.durationMinutes} mins', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  if (isScheduledFuture) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Scheduled: ${quiz.scheduledFor!.day}/${quiz.scheduledFor!.month} ${quiz.scheduledFor!.hour}:${quiz.scheduledFor!.minute.toString().padLeft(2, '0')}', 
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (hasAttempted)
              Icon(LucideIcons.checkCircle, color: Colors.green)
            else
              Icon(isScheduledFuture ? LucideIcons.lock : LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showGoalSetupDialog(BuildContext context, LearningGoal goal) {
    final theme = Theme.of(context);
    double selectedHours = goal.goalHours;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Set Weekly Goal",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "How many hours of learning do you want to aim for this week?",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Goal Hours: ${selectedHours.toStringAsFixed(0)}h",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: selectedHours,
                      min: 1,
                      max: 40,
                      divisions: 39,
                      label: "${selectedHours.toStringAsFixed(0)}h",
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      onChanged: (val) {
                        setState(() {
                          selectedHours = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [5, 10, 15, 20, 30].map((hours) {
                        final isSelected = selectedHours.round() == hours;
                        return ChoiceChip(
                          label: Text("${hours}h"),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedHours = hours.toDouble();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text("Updating weekly goal..."),
                                ],
                              ),
                              duration: Duration(days: 1),
                            ),
                          );

                          try {
                            await ref.read(learningServiceProvider).updateWeeklyGoalHours(selectedHours);
                            ref.invalidate(weeklyGoalProvider);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Weekly learning goal updated successfully!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Failed to update goal: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Save Goal",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../profile/profile_provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';

/// Stitch 01 Dashboard — Enhanced Discover with Hero Section
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final allCourses = ref.watch(courseProvider);

    // Safe top padding for glass nav bar overlap
    final topNavHeight = MediaQuery.of(context).padding.top + 72;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ──── Hero Section ────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, topNavHeight + 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF0F0B1A),
                    theme.colorScheme.primary.withOpacity(0.95),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome text
                  Text(
                    "Transform Your\nFuture with NLIT",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Hands-on tech training & internships in Java, Python, AutoCAD, Revit, MATLAB and more.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // CTA row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/catalog'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Browse Courses", style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.arrowRight, size: 16, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showCourseSelectionModal(context, allCourses),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text("Enroll Now", style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats row inside hero
                  Row(
                    children: [
                      _heroStat("11+", "Courses"),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _heroStat("5000+", "Students"),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _heroStat("98%", "Success"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ──── Profile Stats Grid ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildStatsGrid(context, profile),
            ),
          ),

          // ──── Section Header ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: _buildSectionHeader(context),
            ),
          ),

          // ──── Horizontal Course Card Scroll ────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 310,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allCourses.where((c) => c.slug != 'general').length,
                itemBuilder: (_, i) {
                  final filteredCourses = allCourses.where((c) => c.slug != 'general').toList();
                  return Padding(
                    padding: EdgeInsets.only(right: i < filteredCourses.length - 1 ? 16 : 0),
                    child: _buildCourseCard(context, filteredCourses[i]),
                  );
                },
              ),
            ),
          ),

          // ──── Featured badges row ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Why Choose NLIT?", style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _featurePill(context, LucideIcons.award, "Certified"),
                      const SizedBox(width: 10),
                      _featurePill(context, LucideIcons.briefcase, "Internship"),
                      const SizedBox(width: 10),
                      _featurePill(context, LucideIcons.bookOpen, "Mentors"),
                      const SizedBox(width: 10),
                      _featurePill(context, LucideIcons.laptop, "Hands-on"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }

  Widget _featurePill(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserProfile? profile) {
    return Row(
      children: [
        Expanded(child: _statBox(context, "${profile?.enrollmentsCount ?? 0}", "ENROLLMENTS", LucideIcons.graduationCap)),
        const SizedBox(width: 12),
        Expanded(child: _statBox(context, "${profile?.certificatesCount ?? 0}", "CERTIFICATES", LucideIcons.award)),
        const SizedBox(width: 12),
        Expanded(child: _statBox(context, "${profile?.avgGrade ?? 4.8}", "GRADE", LucideIcons.star)),
      ],
    );
  }

  Widget _statBox(BuildContext context, String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, height: 1.1)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text("Foundation Courses", style: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
        GestureDetector(
          onTap: () => context.go('/catalog'),
          child: Text("VIEW ALL", style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 1.2)),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GestureDetector(
      onTap: () => context.push('/course/${course.slug}', extra: course),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Immersive Image Area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Hero(
                          tag: 'hero_discover_${course.slug}',
                          child: Image.network(course.imageUrl, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(LucideIcons.bookOpen, size: 50, color: AppTheme.outline)),
                        ),
                      ),
                    ),
                    // Category Pill
                    Positioned(
                      top: 14, left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Text(course.category, style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w800, color: course.categoryColor, letterSpacing: 1)),
                      ),
                    ),
                    if (course.isBestseller)
                      Positioned(
                        top: 14, right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                          child: Text("★ TOP", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom Content Area
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 13, color: AppTheme.outline),
                      const SizedBox(width: 5),
                      Text(course.duration, style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 14),
                      const Icon(LucideIcons.star, size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text("${course.rating}", style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(course.level, style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseSelectionModal(BuildContext context, List<Course> allCourses) {
    final theme = Theme.of(context);
    final courses = allCourses.where((c) => c.slug != 'general').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("Select a Course", style: GoogleFonts.plusJakartaSans(
                fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text("Choose the course you want to enroll in.", style: GoogleFonts.inter(
                fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: courses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/enroll/${course.slug}', extra: course);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: course.categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(LucideIcons.bookOpen, color: course.categoryColor, size: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.title, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text("${course.duration} • ${course.level}", style: GoogleFonts.inter(
                                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

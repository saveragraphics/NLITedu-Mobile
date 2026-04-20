import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/enrollment_service.dart';

/// Immersive Course Details Screen with enhanced content sections
class CourseDetailsScreen extends ConsumerWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEnrolledAsync = ref.watch(isEnrolledProvider(course.title));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context),
                _buildQuickStats(context),
                _buildInstructorRow(context),
                _buildAboutSection(context),
                if (course.highlights.isNotEmpty) _buildHighlightsSection(context),
                if (course.syllabus.isNotEmpty) _buildSyllabusSection(context),
                _buildWhyNLIT(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Sticky Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(context, ref, isEnrolledAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 440,
          color: const Color(0xFF0F0B1A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: 'hero_discover_${course.slug}',
                child: Image.network(course.imageUrl, fit: BoxFit.contain, height: 220,
                  errorBuilder: (_, __, ___) => Icon(LucideIcons.bookOpen, size: 100, color: Colors.white.withOpacity(0.3))),
              ),
            ],
          ),
        ),
        Container(
          height: 440,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                const Color(0xFF0F0B1A),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circularButton(LucideIcons.arrowLeft, () => context.pop()),
                _circularButton(LucideIcons.share2, () {}),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (course.isBestseller) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                      child: Text("BESTSELLER", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: course.categoryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(course.category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: course.categoryColor, letterSpacing: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(course.title, style: GoogleFonts.plusJakartaSans(
                fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -1)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _headerInfoTag(LucideIcons.clock, course.duration),
                  _headerInfoTag(LucideIcons.barChart, course.level),
                  _headerInfoTag(LucideIcons.globe, "English"),
                  _headerInfoTag(LucideIcons.star, "${course.rating}"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2))),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _headerInfoTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          _statCard(context, LucideIcons.users, "${course.totalReviews}+", "Students"),
          const SizedBox(width: 12),
          _statCard(context, LucideIcons.star, "${course.rating}", "Rating"),
          const SizedBox(width: 12),
          _statCard(context, LucideIcons.bookOpen, "${course.syllabus.length}", "Modules"),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorRow(BuildContext context) {
    final theme = Theme.of(context);
    final isAsset = course.instructorImage.startsWith('assets/');
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: isAsset 
                    ? AssetImage(course.instructorImage) as ImageProvider
                    : NetworkImage(course.instructorImage), 
                  fit: BoxFit.cover
                ),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Official Partner", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text("NLITedu Official", style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text("${course.rating}", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  ],
                ),
                Text("Verified", style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About the Course", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          Text(course.description, style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurfaceVariant, height: 1.7)),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What you'll get", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 20),
          ...course.highlights.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, size: 14, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(h, style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSyllabusSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Course Curriculum", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text("${course.syllabus.length} Modules", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: course.syllabus.asMap().entries.map((entry) {
                final isLast = entry.key == course.syllabus.length - 1;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary.withOpacity(0.12), theme.colorScheme.primary.withOpacity(0.05)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text("${entry.key + 1}", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Module ${entry.key + 1}", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(entry.value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.playCircle, size: 18, color: theme.colorScheme.outline),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyNLIT(BuildContext context) {
    final theme = Theme.of(context);
    final perks = [
      {"icon": LucideIcons.award, "title": "NLIT Certification", "desc": "Industry-recognized certificate on completion"},
      {"icon": LucideIcons.briefcase, "title": "Internship Included", "desc": "Live project internship with certificate"},
      {"icon": LucideIcons.headphones, "title": "Mentor Support", "desc": "1-on-1 doubt clearing & career guidance"},
      {"icon": LucideIcons.laptop, "title": "Hands-On Labs", "desc": "Real tools, real projects, real skills"},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Why NLIT?", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: perks.length,
            itemBuilder: (_, i) {
              final p = perks[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(p["icon"] as IconData, size: 22, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(p["title"] as String, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(p["desc"] as String, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, AsyncValue<bool> isEnrolledAsync) {
    final theme = Theme.of(context);
    return isEnrolledAsync.when(
      data: (isEnrolled) {
        if (isEnrolled) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, -10))],
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text("Enrolled", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.green)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.go('/learning-hub'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Go to Class", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, -10))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Fee Details", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                    Text("Calculated at Enrollment", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/enroll/${course.slug}', extra: course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Enroll Now", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(height: 100, color: theme.colorScheme.surface, alignment: Alignment.center, child: const CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

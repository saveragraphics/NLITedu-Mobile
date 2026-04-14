import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../profile/profile_provider.dart';

/// Stitch 01 Dashboard — Bento Grid + High Fidelity Course Cards
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const List<Map<String, dynamic>> _courses = [
    {
      'title': 'Python Programming',
      'category': 'DATA SCIENCE',
      'duration': '8 Weeks',
      'rating': 4.9,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/python.png',
      'slug': 'python-programming',
    },
    {
      'title': 'AutoCAD 2D/3D',
      'category': 'ENGINEERING',
      'duration': '10 Weeks',
      'rating': 4.7,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/autocad.png',
      'slug': 'autocad-2d-3d-design',
    },
    {
      'title': 'Java Programming',
      'category': 'DEVELOPMENT',
      'duration': '12 Weeks',
      'rating': 4.8,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/java.png',
      'slug': 'java-programming',
    },
    {
      'title': 'Revit BIM',
      'category': 'ARCHITECTURE',
      'duration': '6 Weeks',
      'rating': 4.6,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/revit.jpg',
      'slug': 'revit-bim',
    },
    {
      'title': 'SolidWorks',
      'category': 'DESIGN',
      'duration': '8 Weeks',
      'rating': 4.8,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/solid2.png',
      'slug': 'solidworks',
    },
    {
      'title': 'CATIA',
      'category': 'AEROSPACE',
      'duration': '14 Weeks',
      'rating': 4.9,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/CATI2.png',
      'slug': 'catia',
    },
    {
      'title': 'Android / iOS',
      'category': 'DEVELOPMENT',
      'duration': '16 Weeks',
      'rating': 4.7,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/iosand2.png',
      'slug': 'android-ios-mobile-development',
    },
    {
      'title': 'MATLAB',
      'category': 'ENGINEERING',
      'duration': '6 Weeks',
      'rating': 4.5,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/matlab2.png',
      'slug': 'matlab-scientific-computing',
    },
    {
      'title': 'STAAD Pro',
      'category': 'CIVIL',
      'duration': '8 Weeks',
      'rating': 4.8,
      'image': 'https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/staadpro.jpg',
      'slug': 'staadpro',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 72),
                  _buildStatsGrid(profile),
                  const SizedBox(height: 36),
                  _buildSectionHeader(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _courses.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < _courses.length - 1 ? 16 : 0),
                    child: _buildCourseCard(context, _courses[i]),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile? profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox("12h", "THIS WEEK", null)),
            const SizedBox(width: 12),
            Expanded(child: _statBox("${profile?.certificatesCount ?? 0}", "CERTIFICATES", null)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statBox("${profile?.enrollmentsCount ?? 0}", "ENROLLMENTS", LucideIcons.graduationCap)),
            const SizedBox(width: 12),
            Expanded(child: _statBox("${profile?.avgGrade ?? 4.8}", "AVG GRADE", LucideIcons.star)),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData? icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(height: 12),
          ],
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.onSurface, height: 1.1)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text("Foundation Courses", style: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.onSurface, letterSpacing: -0.5)),
        GestureDetector(
          onTap: () => context.go('/catalog'),
          child: Text("VIEW ALL", style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.2)),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    return GestureDetector(
      onTap: () => context.push('/course/${course['slug']}', extra: course),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Stack(
                  children: [
                    // Dynamic logo
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Hero(
                          tag: 'hero_${course['slug']}',
                          child: Image.network(course['image'], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    // Category Pill
                    Positioned(
                      top: 16, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                          ],
                        ),
                        child: Text(course['category'], style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Content Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['title']!, style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AppTheme.outline),
                      const SizedBox(width: 6),
                      Text(course['duration'], style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.star, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text("${course['rating']}", style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.graduationCap, size: 18, color: AppTheme.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowRight, size: 20, color: Colors.white),
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
}

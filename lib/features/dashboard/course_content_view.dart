import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/course.dart';

class CourseContentView extends ConsumerWidget {
  final Course course;

  const CourseContentView({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ──── Premium Header ────
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF0F0B1A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, 
                  fontWeight: FontWeight.w800, 
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
                )),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(course.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          const Color(0xFF0F0B1A),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // ──── Course Quick Stats ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                   _statChip(LucideIcons.bookOpen, "${course.syllabus.length} Modules"),
                   const SizedBox(width: 12),
                   _statChip(LucideIcons.clock, course.duration),
                   const SizedBox(width: 12),
                   _statChip(LucideIcons.award, "Certification"),
                ],
              ),
            ),
          ),

          // ──── Curriculum Section ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Course Curriculum", 
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text("Your learning roadmap for ${course.title}", 
                    style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final module = course.syllabus[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _buildModuleCard(context, index + 1, module),
                );
              },
              childCount: course.syllabus.length,
            ),
          ),

          // ──── Support Card ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.helpCircle, size: 40, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text("Need Mentor Help?", 
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text("Connect with our expert mentors for 1-on-1 doubt clearing.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: const Text("Ask Mentor"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, int num, String title) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text("$num", style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MODULE $num", style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.primary),
        ],
      ),
    );
  }
}

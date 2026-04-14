import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// Immersive Course Details Screen matching the provided Figma screenshot
class CourseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> courseData;

  const CourseDetailsScreen({super.key, required this.courseData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context),
                _buildInstructorRow(),
                _buildAboutSection(),
              ],
            ),
          ),
          // Sticky Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        // Dark Base + Image
        Container(
          width: double.infinity,
          height: 480,
          color: const Color(0xFF0F0B1A), // Dark slate/purple base
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: 'hero_${courseData['slug']}',
                child: Image.network(courseData['image'], fit: BoxFit.contain, height: 260),
              ),
            ],
          ),
        ),
        // Gradient overlay
        Container(
          height: 480,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                const Color(0xFF0F0B1A),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Safe Area Top Controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.heart, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
        ),
        // Positioned Content: Bestseller Pill and Title
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A0DAD), // Vibrant purple
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text("BESTSELLER", style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 16),
              Text(courseData['title'], style: GoogleFonts.plusJakartaSans(
                fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorRow() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage("https://ui-avatars.com/api/?name=Alex+Rivera&background=random"), 
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Instructor", style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                  Text("Alex Rivera", style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 18, color: Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              Text("${courseData['rating']}", style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              const SizedBox(width: 4),
              Text("(2.4k reviews)", style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About the Course", style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 16),
          Text(
            "Learn how to design, build, and deploy high-scale systems using modern patterns and tools. This course covers everything from basic fundamentals to event-driven architectures and orchestration.",
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
             color: AppTheme.onSurface.withOpacity(0.04), 
             offset: const Offset(0, -10), blurRadius: 40,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Full Lifetime Access", style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.outline)),
              const SizedBox(height: 2),
              Text("\$49.99", style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
            ],
          ),
          SizedBox(
            width: 180,
            height: 56,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C00C2), // Exact vibrant purple from CTA
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("Enroll Now", style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

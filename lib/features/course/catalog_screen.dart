import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';

/// Stitch 01 Course Catalog
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final List<String> _filters = ["All Courses", "Development", "Design", "Business", "Data Science", "Marketing"];
  int _selectedFilter = 0;

  List<Course> _filteredCourses = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Initialize will be handled in build or didChangeDependencies if logic was complex, 
    // but here we can just compute it in build for simplicity since it's a static list.
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = ref.watch(courseProvider);
    
    // Filtering logic
    final invitedFilter = _filters[_selectedFilter].toUpperCase();
    final filteredCourses = allCourses.where((course) {
      final matchesFilter = _selectedFilter == 0 || course.category == invitedFilter || 
                            (_selectedFilter == 1 && course.category == "PROGRAMMING") ||
                            (_selectedFilter == 2 && course.category == "DESIGN") ||
                            (_selectedFilter == 3 && course.category == "BUSINESS") ||
                            (_selectedFilter == 4 && course.category == "DATA SCIENCE") ||
                            (_selectedFilter == 5 && course.category == "MARKETING");
                            
      final matchesSearch = course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            course.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Title
                    Text.rich(
                      TextSpan(
                        text: 'What will you ',
                        children: [
                          TextSpan(
                            text: 'master\n',
                            style: TextStyle(color: AppTheme.primary),
                          ),
                          const TextSpan(text: 'today?'),
                        ],
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: AppTheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
            // Horizontal Filters
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _filterChip(
                      _filters[index],
                      index == _selectedFilter,
                      () => setState(() => _selectedFilter = index),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            // Course List
            if (filteredCourses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.searchX, size: 48, color: AppTheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("No courses found", style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildCourseCard(context, filteredCourses[index]),
                      );
                    },
                    childCount: filteredCourses.length,
                  ),
                ),
              ),
            // Daily Spotlight
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                child: _buildSpotlightCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.inter(fontSize: 16, color: AppTheme.onSurface),
        decoration: InputDecoration(
          hintText: "Search for courses, skills, or mentors...",
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
          prefixIcon: const Icon(LucideIcons.search, size: 22, color: AppTheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
        )),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GestureDetector(
      onTap: () => context.push('/course/${course.slug}', extra: course),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.surfaceContainerLowest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Hero(
                tag: 'hero_discover_${course.slug}',
                child: Image.network(
                  course.imageUrl, 
                  fit: BoxFit.contain, // Match website's object-contain
                  errorBuilder: (context, error, stackTrace) {
                     return Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(LucideIcons.image, color: AppTheme.outline),
                           const SizedBox(height: 8),
                           Text("Thumbnail", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline)),
                         ],
                       ),
                     );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Meta Row (Category & Rating)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.category,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: course.categoryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text("${course.rating}", style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              course.title, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, 
                fontWeight: FontWeight.w800, 
                color: AppTheme.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              course.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: AppTheme.outline),
                    const SizedBox(width: 4),
                    Text(course.duration, style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    const Icon(LucideIcons.barChart2, size: 14, color: AppTheme.outline),
                    const SizedBox(width: 4),
                    Text(course.level, style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
                Text(course.price, style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text("DAILY SPOTLIGHT", style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF4D118B), letterSpacing: 1.2)),
          ),
          const SizedBox(height: 20),
          Text("Complete UI/UX Design Career Path", style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.onSurface, height: 1.2)),
          const SizedBox(height: 12),
          Text("Join 2,400+ students in our most comprehensive design track. Master Figma, Webflow, and UX Research.", 
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://othxceezbpfiauaevibt.supabase.co/storage/v1/object/public/course-thumbnails/uiux.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text("View Learning Path", style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


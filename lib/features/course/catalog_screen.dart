import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_service.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final List<String> _filters = ["All", "Programming", "Design", "Engineering", "Data Science", "Marketing"];
  int _selectedFilter = 0;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final allCourses = ref.watch(courseProvider);
    final trendingCourses = allCourses.where((c) => c.isBestseller).toList();
    
    final filteredCourses = allCourses.where((course) {
      final matchesFilter = _selectedFilter == 0 || 
                            course.category.toLowerCase() == _filters[_selectedFilter].toLowerCase();
                            
      final matchesSearch = course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            course.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesFilter && matchesSearch;
    }).toList();

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildFiltersBar(),
                if (_searchQuery.isEmpty && _selectedFilter == 0) ...[
                   _buildSectionHeader("Trending Now", true),
                   _buildTrendingCarousel(trendingCourses),
                   const SizedBox(height: 32),
                ],
                _buildSectionHeader(_selectedFilter == 0 ? "All Courses" : _filters[_selectedFilter], false),
              ],
            ),
          ),
          if (filteredCourses.isEmpty)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: EnhancedCourseCard(course: filteredCourses[index]),
                  ),
                  childCount: filteredCourses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 90, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF0F0B1A),
              theme.colorScheme.primary.withOpacity(0.9),
            ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Discover", style: GoogleFonts.plusJakartaSans(
                      fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Text("Master new skills daily", style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    final generalCourse = ref.read(courseProvider).firstWhere((c) => c.slug == 'general');
                    context.push('/enroll/general', extra: generalCourse);
                  },
                  tooltip: 'Quick Enroll',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search courses, topics...",
                  hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _buildModernChip(context, _filters[i], i == _selectedFilter, () => setState(() => _selectedFilter = i)),
        ),
      ),
    );
  }

  Widget _buildModernChip(BuildContext context, String label, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isTrending) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isTrending) const Icon(LucideIcons.flame, color: Colors.orange, size: 22),
              if (isTrending) const SizedBox(width: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
            ],
          ),
          if (isTrending) Text("VIEW ALL", style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildTrendingCarousel(List<Course> courses) {
    return SizedBox(
      height: 340,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: courses.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 20),
          child: TrendingCourseCard(course: courses[i]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(LucideIcons.searchX, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text("No courses found", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class TrendingCourseCard extends ConsumerWidget {
  final Course course;
  const TrendingCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEnrolledAsync = ref.watch(isEnrolledProvider(course.title));

    return GestureDetector(
      onTap: () => context.push('/course/${course.slug}', extra: course),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: theme.colorScheme.surfaceContainerLowest,
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary.withOpacity(0.05), theme.colorScheme.surfaceContainerLowest],
          ),
          boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Hero(tag: 'hero_discover_${course.slug}', child: Image.network(course.imageUrl, fit: BoxFit.contain)),
                  )),
                  Positioned(top: 20, left: 20, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Text("TRENDING", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
                  )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.users, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text("2.4k Students", style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      isEnrolledAsync.when(
                        data: (isEnrolled) => GestureDetector(
                          onTap: isEnrolled ? null : () => context.push('/course/${course.slug}', extra: course),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isEnrolled ? Colors.green.withOpacity(0.12) : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isEnrolled) ...[
                                  const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isEnrolled ? "ENROLLED" : "ENROLL NOW",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isEnrolled ? Colors.green : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(width: 80, height: 32),
                        error: (_, __) => const SizedBox.shrink(),
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

class EnhancedCourseCard extends ConsumerWidget {
  final Course course;
  const EnhancedCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEnrolledAsync = ref.watch(isEnrolledProvider(course.title));

    return GestureDetector(
      onTap: () => context.push('/course/${course.slug}', extra: course),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))],
        ),
        child: Row(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  Center(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Hero(tag: 'hero_discover_list_${course.slug}', child: Image.network(course.imageUrl, fit: BoxFit.contain)),
                  )),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(course.category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: course.categoryColor, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(course.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoTag(context, LucideIcons.clock, course.duration),
                      const SizedBox(width: 12),
                      _infoTag(context, LucideIcons.star, "${course.rating}"),
                    ],
                  ),
                  if (course.slug != 'general') ...[
                    const SizedBox(height: 8),
                    isEnrolledAsync.when(
                      data: (isEnrolled) => GestureDetector(
                        onTap: isEnrolled ? null : () => context.push('/enroll/${course.slug}', extra: course),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isEnrolled ? Colors.green.withOpacity(0.12) : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEnrolled) ...[
                                const Icon(LucideIcons.checkCircle2, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                isEnrolled ? "ENROLLED" : "ENROLL NOW",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isEnrolled ? Colors.green : theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(height: 24),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            if (course.slug == 'general')
              Icon(LucideIcons.chevronRight, size: 20, color: theme.colorScheme.outlineVariant)
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoTag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

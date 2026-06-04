import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/course.dart';
import '../../models/learning_models.dart';
import '../../providers/learning_service.dart';
import '../course/secure_video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../profile/profile_provider.dart';

class CourseContentView extends ConsumerWidget {
  final Course course;

  const CourseContentView({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordingsAsync = ref.watch(courseRecordingsProvider(course.title));
    final profile = ref.watch(profileProvider);
    
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

          // ──── Class Recordings Section ────
          recordingsAsync.when(
            data: (recordings) {
              if (recordings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.playCircle, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text("Class Recordings", 
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recordings.length,
                          itemBuilder: (context, index) {
                            final r = recordings[index];
                            final date = DateTime.tryParse(r.recordedAt) ?? DateTime.now();
                            
                            final videoId = YoutubePlayer.convertUrlToId(r.videoUrl);
                            final thumbnailUrl = videoId != null 
                                ? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg'
                                : null;

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (context) => SecureVideoPlayer(
                                      videoUrl: r.videoUrl,
                                      topic: r.topic,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 240,
                                margin: const EdgeInsets.only(right: 16),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                                  image: thumbnailUrl != null ? DecorationImage(
                                    image: NetworkImage(thumbnailUrl),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                                  ) : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: thumbnailUrl != null ? Colors.black45 : theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          DateFormat('dd MMM yyyy').format(date),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: thumbnailUrl != null ? Colors.white : theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        r.topic,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: thumbnailUrl != null ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.play, size: 14, color: thumbnailUrl != null ? Colors.white : AppTheme.primary),
                                          const SizedBox(width: 6),
                                          Text("Watch Class in HD", 
                                            style: GoogleFonts.inter(
                                              fontSize: 12, 
                                              fontWeight: FontWeight.w700, 
                                              color: thumbnailUrl != null ? Colors.white : AppTheme.primary
                                            )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ──── Study Materials Section ────
          ref.watch(studyMaterialsProvider(course.title)).when(
            data: (materials) {
              if (materials.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.fileText, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text("Study Materials", 
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: materials.length,
                          itemBuilder: (context, index) {
                            final m = materials[index];
                            return GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(m.documentUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.fileText, size: 32, color: Colors.blue),
                                    const Spacer(),
                                    Text(
                                      m.topic,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tap to open PDF",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
                      onPressed: () async {
                        final name = profile?.fullName ?? "Student";
                        final email = profile?.email ?? "Not provided";
                        final courseName = course.title;
                        final message = "Hello Team,\n\nMy name is $name.\nEmail: $email\nCourse: $courseName\n\nI need help with...";
                        final encodedMsg = Uri.encodeComponent(message);
                        final uri = Uri.parse("https://wa.me/918092378320?text=$encodedMsg");
                        
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not open WhatsApp")),
                            );
                          }
                        }
                      },
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

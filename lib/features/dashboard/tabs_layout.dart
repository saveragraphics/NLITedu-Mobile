import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

/// Stitch 01 Tabs Layout — Glass nav with correct tab order
class TabsLayout extends StatelessWidget {
  final Widget child;
  const TabsLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // TopAppBar — glass
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 8, 24, 12),
                  decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        // Profile image from Supabase
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryFixed,
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(avatarUrl, fit: BoxFit.cover, width: 40, height: 40,
                                  errorBuilder: (_, __, ___) => const Icon(LucideIcons.user, color: AppTheme.primary, size: 20))
                              : const Icon(LucideIcons.user, color: AppTheme.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("Nexgen Learning", style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppTheme.primary, letterSpacing: -0.5)),
                      ]),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.bell, size: 22, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // BottomNavBar — CORRECTED order: Dashboard(Home), Discover(Catalog), My Hub, Profile
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(
                      color: AppTheme.onSurface.withOpacity(0.04),
                      blurRadius: 40, offset: const Offset(0, -10),
                    )],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(context, LucideIcons.compass, "Discover", "/catalog"),
                          _navItem(context, LucideIcons.bookOpen, "My Learning", "/learning-hub"),
                          _navItem(context, LucideIcons.award, "Achievements", "/achievements"),
                          _navItem(context, LucideIcons.user, "Profile", "/profile"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String path) {
    final isActive = GoRouterState.of(context).uri.path == path;
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isActive ? BoxDecoration(
          color: AppTheme.primaryFixed.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
              color: isActive ? AppTheme.primary : const Color(0xFF9CA3AF)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppTheme.primary : const Color(0xFF9CA3AF)),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(width: 4, height: 4,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary)),
            ],
          ],
        ),
      ),
    );
  }
}

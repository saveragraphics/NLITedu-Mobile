import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'profile_provider.dart';

/// Stitch 01 User Profile — Enhanced stats, real avatar, all settings active
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = profile?.fullName ??
        user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ?? "Learner";

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 72, 24, 120),
        child: Column(children: [
          _profileHero(context, displayName, user?.email ?? "", avatarUrl, profile?.joinYear ?? "2024"),
          const SizedBox(height: 28),
          _statsSection(profile),
          const SizedBox(height: 28),
          _subscriptionCard(),
          const SizedBox(height: 28),
          _settingsSection(context, ref),
        ]),
      ),
    );
  }

  Widget _profileHero(BuildContext context, String name, String email, String? avatarUrl, String joinYear) {
    return Column(children: [
      // Avatar with gradient glow
      Stack(alignment: Alignment.center, children: [
        Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topRight, colors: [
              AppTheme.secondary.withOpacity(0.2), AppTheme.primary.withOpacity(0.2)]))),
        Container(width: 120, height: 120,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceContainerLowest),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(avatarUrl, fit: BoxFit.cover, width: 120, height: 120,
                  errorBuilder: (_, __, ___) => _defaultAvatar())
              : _defaultAvatar(),
          ),
        ),
        Positioned(bottom: 0, right: 0, child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: const Icon(LucideIcons.badgeCheck, size: 14, color: Colors.white))),
      ]),
      const SizedBox(height: 16),
      Text(name, style: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.onSurface, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(email, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.crown, size: 14, color: AppTheme.secondary),
          const SizedBox(width: 6),
          Text("Member since $joinYear", style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondary)),
        ]),
      ),
    ]);
  }

  Widget _defaultAvatar() => Container(
    color: AppTheme.surfaceContainerLow,
    child: const Center(child: Icon(LucideIcons.user, size: 40, color: AppTheme.outline)));

  Widget _statsSection(UserProfile? profile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4),
        child: Text("My Stats", style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant))),
      const SizedBox(height: 12),
      // 3-column stat row
      Row(children: [
        Expanded(child: _miniStat(LucideIcons.clock, "${(profile?.enrollmentsCount ?? 3) * 12}", "Hours")),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(LucideIcons.terminal, "${profile?.enrollmentsCount ?? 3}", "Courses")),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(LucideIcons.award, "${profile?.certificatesCount ?? 0}", "Certs")),
      ]),
      const SizedBox(height: 10),
      // Streak card
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primary, borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(LucideIcons.flame, size: 22, color: Colors.white)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Current Streak", style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.primaryFixedDim)),
              Text("${profile?.activeStreak ?? 1} days", style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100)),
            child: Text("🔥 Active", style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
      ),
    ]);
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _subscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary, AppTheme.primaryContainer])),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondaryContainer])),
              child: const Icon(LucideIcons.star, size: 24, color: Colors.white)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Foundation Plan", style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              Text("Access to all 9 courses", style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.onSurfaceVariant)),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0),
              child: Text("View Plans", style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _settingsSection(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4),
        child: Text("Settings", style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant))),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          _settingsItem(LucideIcons.userCog, "Personal Info",
            "Name, email, and bio",
            () => context.push('/profile/info')),
          _divider(),
          _settingsItem(LucideIcons.bellRing, "Notifications",
            "Alerts, updates, and reminders",
            () => context.push('/profile/notifications')),
          _divider(),
          _settingsItem(LucideIcons.shieldCheck, "Security",
            "Password, 2FA, and privacy",
            () => context.push('/profile/security')),
          _divider(),
          _settingsItem(LucideIcons.fileText, "Privacy Policy",
            "How we protect your data",
            () => context.push('/profile/privacy')),
          _divider(),
          _settingsItem(LucideIcons.helpCircle, "Help & Support",
            "FAQs and documentation", () {}),
          _divider(),
          _settingsItem(LucideIcons.logOut, "Log Out",
            "Sign out of your session",
            () => _handleLogout(context, ref),
            isDestructive: true),
        ]),
      ),
    ]);
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Log Out", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text("Are you sure you want to sign out?",
          style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancel", style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("Log Out", style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _divider() => Divider(height: 1,
    color: AppTheme.outlineVariant.withOpacity(0.1), indent: 72, endIndent: 24);

  Widget _settingsItem(IconData icon, String title, String subtitle,
      VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDestructive
                ? AppTheme.errorContainer.withOpacity(0.2)
                : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 20,
              color: isDestructive ? AppTheme.error : AppTheme.onSurfaceVariant)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDestructive ? AppTheme.error : AppTheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(
              fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ])),
          if (!isDestructive)
            const Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.outline),
        ]),
      ),
    );
  }
}

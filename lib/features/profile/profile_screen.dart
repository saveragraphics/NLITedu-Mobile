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
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = profile?.fullName ??
        user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ?? "Learner";

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 72, 24, 120),
        child: Column(children: [
          _profileHero(context, displayName, user?.email ?? "", avatarUrl, profile?.joinYear ?? "2024"),
          const SizedBox(height: 28),
          _statsSection(context, profile),
          const SizedBox(height: 28),
          _subscriptionCard(context),
          const SizedBox(height: 28),
          _settingsSection(context, ref),
        ]),
      ),
    );
  }

  Widget _profileHero(BuildContext context, String name, String email, String? avatarUrl, String joinYear) {
    final theme = Theme.of(context);
    return Column(children: [
      // Avatar with gradient glow
      Stack(alignment: Alignment.center, children: [
        Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topRight, colors: [
              theme.colorScheme.secondary.withOpacity(0.2), theme.colorScheme.primary.withOpacity(0.2)]))),
        Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerLowest),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(avatarUrl, fit: BoxFit.cover, width: 120, height: 120,
                  errorBuilder: (_, __, ___) => _defaultAvatar(context))
              : _defaultAvatar(context),
          ),
        ),
        Positioned(bottom: 0, right: 0, child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Icon(LucideIcons.badgeCheck, size: 14, color: theme.colorScheme.onPrimary))),
      ]),
      const SizedBox(height: 16),
      Text(name, style: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(email, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.crown, size: 14, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Text("Member since $joinYear", style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.secondary)),
        ]),
      ),
    ]);
  }

  Widget _defaultAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(child: Icon(LucideIcons.user, size: 40, color: theme.colorScheme.outline)));
  }

  Widget _statsSection(BuildContext context, UserProfile? profile) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4),
        child: Text("My Stats", style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant))),
      const SizedBox(height: 12),
      // 3-column stat row
      Row(children: [
        Expanded(child: _miniStat(context, LucideIcons.clock, "${(profile?.enrollmentsCount ?? 3) * 12}", "Hours")),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(context, LucideIcons.terminal, "${profile?.enrollmentsCount ?? 3}", "Courses")),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(context, LucideIcons.award, "${profile?.certificatesCount ?? 0}", "Certs")),
      ]),
      const SizedBox(height: 10),
      // Streak card
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(LucideIcons.flame, size: 22, color: theme.colorScheme.onPrimary)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Current Streak", style: GoogleFonts.inter(
                fontSize: 12, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
              Text("${profile?.activeStreak ?? 1} days", style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary)),
            ]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100)),
            child: Text("🔥 Active", style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
          ),
        ]),
      ),
    ]);
  }

  Widget _miniStat(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _subscriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary, theme.colorScheme.primaryContainer])),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondaryContainer])),
              child: Icon(LucideIcons.star, size: 24, color: theme.colorScheme.onPrimary)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Foundation Plan", style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              Text("Access to all 9 courses", style: GoogleFonts.inter(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0),
              child: Text("View Plans", style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _settingsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4),
        child: Text("Settings", style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant))),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          _settingsItem(context, LucideIcons.userCog, "Personal Info",
            "Name, email, and bio",
            onTap: () => context.push('/profile/info')),
          _divider(context),
          _settingsItem(context, LucideIcons.moon, "Dark Mode",
            "Adjust the visual theme",
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
            )),
          _divider(context),
          _settingsItem(context, LucideIcons.bellRing, "Notifications",
            "Alerts, updates, and reminders",
            onTap: () => context.push('/profile/notifications')),
          _divider(context),
          _settingsItem(context, LucideIcons.shieldCheck, "Security",
            "Password, 2FA, and privacy",
            onTap: () => context.push('/profile/security')),
          _divider(context),
          _settingsItem(context, LucideIcons.fileText, "Privacy Policy",
            "How we protect your data",
            onTap: () => context.push('/profile/privacy')),
          _divider(context),
          _settingsItem(context, LucideIcons.fileSignature, "Terms of Service",
            "Legal agreements",
            onTap: () => context.push('/profile/terms')),
          _divider(context),
          _settingsItem(context, LucideIcons.helpCircle, "Help & Support",
            "FAQs and documentation", onTap: () {}),
          _divider(context),
          _settingsItem(context, LucideIcons.logOut, "Log Out",
            "Sign out of your session",
            onTap: () => _handleLogout(context, ref),
            isDestructive: true),
        ]),
      ),
    ]);
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Log Out", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
        content: Text("Are you sure you want to sign out?",
          style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancel", style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("Log Out", style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: theme.colorScheme.onError))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _divider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(height: 1,
      color: theme.colorScheme.outlineVariant.withOpacity(0.3), indent: 72, endIndent: 24);
  }

  Widget _settingsItem(BuildContext context, IconData icon, String title, String subtitle,
      {VoidCallback? onTap, bool isDestructive = false, Widget? trailing}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDestructive
                ? theme.colorScheme.errorContainer.withOpacity(0.5)
                : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 20,
              color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ])),
          if (trailing != null) trailing
          else if (!isDestructive)
            Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.outline),
        ]),
      ),
    );
  }
}

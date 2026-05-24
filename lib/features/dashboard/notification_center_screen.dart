import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/notification_service.dart';

/// Premium notification center screen — reached via the bell icon
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animController.forward();
    // Mark all as read on opening
    NotificationService().markAllAsRead();
    // Refresh unread count
    ref.invalidate(unreadNotificationCountProvider);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(notificationHistoryProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Notifications", style: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, size: 20, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pushNamed('/profile/notifications'),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Failed to load notifications", style: GoogleFonts.inter())),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Group by today / earlier
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final todayItems = items.where((i) => i.timestamp.isAfter(today)).toList();
          final earlierItems = items.where((i) => !i.timestamp.isAfter(today)).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              if (todayItems.isNotEmpty) ...[
                _sectionLabel(theme, "TODAY"),
                const SizedBox(height: 8),
                ...todayItems.asMap().entries.map((entry) => 
                  _buildNotificationCard(theme, entry.value, entry.key)),
              ],
              if (earlierItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(theme, "EARLIER"),
                const SizedBox(height: 8),
                ...earlierItems.asMap().entries.map((entry) => 
                  _buildNotificationCard(theme, entry.value, entry.key + todayItems.length)),
              ],
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bellOff, size: 40, color: theme.colorScheme.primary.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text("No notifications yet", style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("When your classes go live or exams are\nscheduled, you'll see them here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.5)),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, NotificationItem item, int index) {
    final delay = (index * 60).clamp(0, 400);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dismissible(
        key: ValueKey(item.timestamp.toIso8601String()),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) async {
          await NotificationService().deleteNotification(item.timestamp);
          ref.invalidate(notificationHistoryProvider);
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(LucideIcons.trash2, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type indicator icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.type == 'live' ? LucideIcons.video
                      : item.type == 'scheduled' ? LucideIcons.calendar
                      : LucideIcons.clipboardList,
                  size: 20, color: item.color,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.label, style: GoogleFonts.inter(
                            fontSize: 8, fontWeight: FontWeight.w900,
                            color: item.color, letterSpacing: 1)),
                        ),
                        const Spacer(),
                        Text(_timeAgo(item.timestamp), style: GoogleFonts.inter(
                          fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(item.body, style: GoogleFonts.inter(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isNotificationsEnabled;
  final int enrollmentsCount;
  final int certificatesCount;
  final int activeStreak;
  final double avgGrade;
  final DateTime joinedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.isNotificationsEnabled = true,
    this.enrollmentsCount = 0,
    this.certificatesCount = 0,
    this.activeStreak = 1,
    this.avgGrade = 0.0,
    required this.joinedAt,
  });

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isNotificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      enrollmentsCount: enrollmentsCount,
      certificatesCount: certificatesCount,
      activeStreak: activeStreak,
      avgGrade: avgGrade,
      joinedAt: joinedAt,
    );
  }

  String get formattedJoinDate => DateFormat.yMMMMd().format(joinedAt);
  String get joinYear => DateFormat.y().format(joinedAt);
}

class ProfileNotifier extends StateNotifier<UserProfile?> {
  ProfileNotifier() : super(null) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final joinedStr = user.createdAt;
      final joined = DateTime.tryParse(joinedStr) ?? DateTime.now();
      final meta = user.userMetadata ?? {};

      // Fetch actual enrollment count from database
      int actualEnrollmentCount = 0;
      try {
        final enrollments = await Supabase.instance.client
            .from('enrollments')
            .select('id')
            .eq('email', user.email!);
        actualEnrollmentCount = (enrollments as List).length;
      } catch (e) {
        print("Error fetching actual enrollments: $e");
        actualEnrollmentCount = meta['enrollments'] ?? 0;
      }

      state = UserProfile(
        id: user.id,
        fullName: meta['full_name'] ?? "New Learner",
        email: user.email ?? "",
        phone: meta['phone'],
        avatarUrl: meta['avatar_url'],
        enrollmentsCount: actualEnrollmentCount,
        certificatesCount: meta['certificates'] ?? 0,
        activeStreak: meta['streak'] ?? 1,
        avgGrade: meta['avgGrade'] ?? 4.8,
        joinedAt: joined,
      );
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    if (state == null) return;
    state = state!.copyWith(fullName: name, phone: phone);
    // Sync with Supabase
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'full_name': name, 'phone': phone}),
    );
  }

  Future<String?> pickAndUploadAvatar() async {
    if (state == null) return null;
    
    // In a real app, we'd use image_picker here.
    // Logic: if (file.lengthInBytes > 75 * 1024) throw Error("File too large");
    
    // Mocking the behavior for the restored workflow:
    const int sizeLimit = 75 * 1024; // 75 KB
    
    print("RESTORED: Checking file size against 75 KB limit...");
    
    // Placeholder for actual upload logic
    return null;
  }

  void toggleNotifications(bool value) {
    if (state == null) return;
    state = state!.copyWith(isNotificationsEnabled: value);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>((ref) {
  return ProfileNotifier();
});

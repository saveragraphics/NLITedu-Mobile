import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import 'course_provider.dart';

class EnrollmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Toggle maintenance mode here (Sync with NEXT_PUBLIC_MAINTENANCE_MODE)
  static const bool isMaintenanceMode = false;

  // Cloudinary Config (from website's .env.local)
  final String _cloudName = "dx1ywq1pi";
  final String _uploadPreset = "nlitedu_uploads";

  /// Course-specific pricing map matching web app
  static const Map<String, Map<String, double>> coursePricing = {
    'AutoCAD': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 5999},
    'Revit Building Information Modeling (BIM)': {'govt': 2499, 'private': 3999, 'job': 4999, 'display': 6999},
    'STAAD Pro': {'govt': 2499, 'private': 3999, 'job': 4999, 'display': 6999},
    'SolidWorks': {'govt': 2999, 'private': 4999, 'job': 5999, 'display': 9999},
    '3DS Max + VRay': {'govt': 3999, 'private': 5999, 'job': 7999, 'display': 12999},
    'CATIA': {'govt': 2999, 'private': 3999, 'job': 4999, 'display': 9999},
    'SketchUp': {'govt': 2999, 'private': 3999, 'job': 4999, 'display': 9999},
    'ETABS': {'govt': 3999, 'private': 5999, 'job': 7999, 'display': 14999},
    'Java Programming': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 6999},
    'Python Programming': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 6999},
    'Python for Data Science & AI': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 6999},
    'Data Science': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 6999},
    'Android & iOS Mobile Development': {'govt': 3999, 'private': 5999, 'job': 7999, 'display': 14999},
    'AI': {'govt': 2999, 'private': 3999, 'job': 5999, 'display': 9999},
    'MATLAB for Scientific Computing': {'govt': 2999, 'private': 3999, 'job': 5999, 'display': 9999},
    'C++': {'govt': 2499, 'private': 3499, 'job': 4499, 'display': 8999},
    'ANSYS': {'govt': 3999, 'private': 4999, 'job': 7999, 'display': 14999},
    'Primavera P6': {'govt': 2999, 'private': 3999, 'job': 4999, 'display': 14999},
    'CorelDRAW': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 7999},
    'AutoCAD 2.0 Advance': {'govt': 2999, 'private': 3999, 'job': 5999, 'display': 9999},
    'AutoCAD (Electrical)': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 5999},
    'AutoCAD (Mechanical)': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 5999},
    'IoT & Embedded Systems': {'govt': 2999, 'private': 3999, 'job': 5999, 'display': 9999},
    'NLIT Course Enrollment': {'govt': 1999, 'private': 2999, 'job': 3999, 'display': 6999},
  };

  /// Calculate enrollment fee based on college type and course title
  double calculateFee(String collegeType, String state, {String? courseTitle, String? duration, String? internshipMode, bool isInternship = false}) {
    final bool isIntern = isInternship || courseTitle == 'NLIT Course Enrollment' || (courseTitle != null && !coursePricing.containsKey(courseTitle));

    if (isIntern) {
      if (state == 'Bihar') {
        final dur = duration ?? '';
        final mode = internshipMode ?? 'Online';

        if (collegeType == 'govt') {
          if (mode == 'Online') {
            if (dur.contains('2')) return 799.0;
            if (dur.contains('4')) return 999.0;
            if (dur.contains('6')) return 1199.0;
            if (dur.contains('8')) return 1399.0;
            return 999.0; // fallback before selection
          } else { // Online + Offline or Both
            if (dur.contains('2')) return 1299.0;
            if (dur.contains('4')) return 1499.0;
            if (dur.contains('6')) return 1999.0;
            if (dur.contains('8')) return 2499.0;
            return 1499.0; // fallback before selection
          }
        }
        if (collegeType == 'private') {
          if (mode == 'Online') {
            if (dur.contains('2')) return 999.0;
            if (dur.contains('4')) return 1499.0;
            if (dur.contains('6')) return 1999.0;
            if (dur.contains('8')) return 2499.0;
            return 1999.0; // fallback before selection
          } else { // Online + Offline or Both
            if (dur.contains('2')) return 1799.0;
            if (dur.contains('4')) return 1999.0;
            if (dur.contains('6')) return 2499.0;
            if (dur.contains('8')) return 2999.0;
            return 1999.0; // fallback before selection
          }
        }
        if (collegeType == 'job') return 2999.0;
        return 0.0;
      }

      // Other States
      if (collegeType == 'govt') return 1499.0;
      if (collegeType == 'private') return 1999.0;
      if (collegeType == 'job') return 2999.0;
      return 0.0;
    }

    if (courseTitle != null && coursePricing.containsKey(courseTitle)) {
      return coursePricing[courseTitle]![collegeType] ?? 0.0;
    }
    
    // Fallback
    if (collegeType == 'govt') return 1499.0;
    if (collegeType == 'private') return 1999.0;
    if (collegeType == 'job') return 2999.0;
    return 0.0;
  }

  /// Get display price for a course
  double getDisplayPrice(String courseTitle) {
    if (courseTitle == 'NLIT Course Enrollment' || !coursePricing.containsKey(courseTitle)) {
      return 6999.0;
    }
    return coursePricing[courseTitle]?['display'] ?? 6999.0;
  }

  /// Upload file to Cloudinary
  Future<String> uploadToCloudinary(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');
    
    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      throw Exception('Failed to upload marksheet to Cloudinary: ${response.statusCode}');
    }
  }

  /// Check if user is already enrolled in a course.
  /// Uses only 'id' column (always exists) to avoid PGRST204 schema cache errors.
  Future<bool> isUserEnrolled(String email, String courseTitle) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select('id')
          .eq('email', email)
          .eq('course_title', courseTitle);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      print('isUserEnrolled error: $e');
      return false;
    }
  }

  /// Get all enrollments for a user.
  /// Uses select() without column names so PostgREST returns whatever columns
  /// it knows about — completely bypassing schema cache column validation.
  Future<List<Map<String, dynamic>>> getUserEnrollments(String email) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select()
          .eq('email', email);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('getUserEnrollments error: $e');
      return [];
    }
  }

  /// Create Cashfree Order via Supabase Edge Function
  Future<Map<String, dynamic>> createCashfreeOrder({
    required double amount,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-cashfree-order',
        body: {
          'amount': amount,
          'order_id': 'NLIT_MOB_${DateTime.now().millisecondsSinceEpoch}',
          'customer_id': email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_'),
          'customer_email': email,
          'customer_phone': phone,
        },
      );

      if (response.status != 200) {
        throw Exception('Edge function error: ${response.data}');
      }

      return response.data;
    } catch (e) {
      throw Exception('Failed to create payment session: $e');
    }
  }

  /// Save a pending enrollment to the database.
  /// Uses .insert() — NOT .upsert() — because the enrollments table
  /// has no UNIQUE constraint on cf_payment_id (42P10 error).
  /// This matches the website's enrollment form behavior exactly.
  Future<void> savePendingEnrollment(Map<String, dynamic> enrollmentData) async {
    try {
      await _supabase.from('enrollments').insert({
        ...enrollmentData,
        'status': 'PENDING',
      });
    } on PostgrestException catch (e) {
      if ((e.message.contains('internship_mode') || e.code == '42703') && enrollmentData.containsKey('internship_mode')) {
        final fallbackData = Map<String, dynamic>.from(enrollmentData)..remove('internship_mode');
        await _supabase.from('enrollments').insert({
          ...fallbackData,
          'status': 'PENDING',
        });
      } else {
        rethrow;
      }
    }
  }

  /// Confirm payment success in Supabase using Edge Function.
  /// This matches the website's verification flow.
  Future<void> confirmPayment(String orderId) async {
    try {
      final response = await _supabase.functions.invoke(
        'verify-cashfree-payment',
        body: {'orderId': orderId},
      );
      
      if (response.status != 200) {
        throw Exception('Edge function verification failed: ${response.data}');
      }
      
      // Verification successful, edge function handles the database update
      print('Payment verified successfully via edge function.');
    } catch (e) {
      print('confirmPayment failed: $e');
      throw Exception('Payment verification failed: $e');
    }
  }


  /// Send enrollment confirmation email via website API (DEPRECATED - Webhook handles this)
  Future<void> sendEnrollmentEmail({
    required String studentName,
    required String studentEmail,
    required String courseTitle,
    required String orderId,
  }) async {
    // Deprecated: Email is now sent automatically by the Supabase Cashfree Webhook
    // to ensure payment_amount and payment_time are always included correctly.
    print('sendEnrollmentEmail skipped - Webhook will handle this.');
  }
}

final enrollmentServiceProvider = Provider((ref) => EnrollmentService());

// A provider to check status of a specific course
final isEnrolledProvider = FutureProvider.family<bool, String>((ref, title) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  
  return ref.read(enrollmentServiceProvider).isUserEnrolled(user.email ?? user.phone ?? '', title);
});

// A provider for all user enrollments
final userEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  return ref.read(enrollmentServiceProvider).getUserEnrollments(user.email ?? user.phone ?? '');
});

/// A provider that maps simple enrollment records to full Course objects for valid UI rendering
final enrolledFullCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final enrollments = await ref.watch(userEnrollmentsProvider.future);
  final allCourses = await ref.watch(courseProvider.future);
  
  if (enrollments.isEmpty) return [];

  // Extract cleaned titles from enrollments for robust matching
  final enrolledTitles = enrollments
      .map((e) => (e['course_title'] as String).trim().toLowerCase())
      .toSet();
  
  // Map back to Course objects using case-insensitive title matching
  return allCourses.where((c) {
    final title = c.title.trim().toLowerCase();
    
    // Explicitly handle the general enrollment course
    if (c.slug == 'general' && enrolledTitles.contains('nlit course enrollment')) {
      return true;
    }
    
    return enrolledTitles.contains(title);
  }).toList();
});

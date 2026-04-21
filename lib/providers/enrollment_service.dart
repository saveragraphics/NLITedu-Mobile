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

  /// Calculate enrollment fee based on college type and state
  double calculateFee(String collegeType, String state) {
    if (collegeType == 'govt') {
      return state == 'Bihar' ? 999.0 : 1499.0;
    }
    return collegeType == 'private' ? 1999.0 : 0.0;
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
    await _supabase.from('enrollments').insert({
      ...enrollmentData,
      'status': 'PENDING',
    });
  }

  /// Confirm payment success in Supabase.
  /// Uses raw HTTP PATCH with Prefer: return=minimal to completely
  /// bypass PostgREST schema cache validation for return columns.
  Future<void> confirmPayment(String orderId) async {
    try {
      // Primary: use Supabase client (no .select())
      await _supabase
          .from('enrollments')
          .update({'status': 'PAID'})
          .eq('cf_payment_id', orderId);
    } catch (e) {
      print('confirmPayment primary failed: $e — trying raw HTTP fallback');
      // Fallback: use raw HTTP PATCH with return=minimal
      await _confirmPaymentViaRest(orderId);
    }
  }

  /// Raw HTTP fallback for confirming payment.
  /// Sends a PATCH directly to the Supabase REST API with
  /// Prefer: return=minimal, ensuring PostgREST never looks up
  /// return columns in its schema cache.
  Future<void> _confirmPaymentViaRest(String orderId) async {
    final supabaseUrl = _supabase.rest.url.replaceAll('/rest/v1', '');
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: '');
    
    // Get the current session's access token for RLS
    final accessToken = _supabase.auth.currentSession?.accessToken ?? anonKey;
    
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/enrollments?cf_payment_id=eq.$orderId'
    );

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey.isNotEmpty ? anonKey : accessToken,
        'Authorization': 'Bearer $accessToken',
        'Prefer': 'return=minimal',
      },
      body: json.encode({'status': 'PAID'}),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('REST fallback failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Send enrollment confirmation email via website API
  Future<void> sendEnrollmentEmail({
    required String studentName,
    required String studentEmail,
    required String courseTitle,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://nlitedu.com/api/email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'studentName': studentName,
          'studentEmail': studentEmail,
          'courseTitle': courseTitle,
          'orderId': orderId,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send enrollment email: ${response.body}');
      }
    } catch (e) {
      print('Error calling email API: $e');
    }
  }
}

final enrollmentServiceProvider = Provider((ref) => EnrollmentService());

// A provider to check status of a specific course
final isEnrolledProvider = FutureProvider.family<bool, String>((ref, title) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  
  return ref.read(enrollmentServiceProvider).isUserEnrolled(user.email!, title);
});

// A provider for all user enrollments
final userEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  return ref.read(enrollmentServiceProvider).getUserEnrollments(user.email!);
});

/// A provider that maps simple enrollment records to full Course objects for valid UI rendering
final enrolledFullCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final enrollments = await ref.watch(userEnrollmentsProvider.future);
  final allCourses = ref.watch(courseProvider);
  
  if (enrollments.isEmpty) return [];

  // Extract titles from enrollments
  final enrolledTitles = enrollments.map((e) => e['course_title'] as String).toSet();
  
  // Map back to Course objects
  return allCourses.where((c) => enrolledTitles.contains(c.title)).toList();
});

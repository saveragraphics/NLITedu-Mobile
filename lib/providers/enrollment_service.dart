import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Check if a user is enrolled in a specific course
  Future<bool> isUserEnrolled(String email, String courseTitle) async {
    try {
      // Try with payment_status column first
      final response = await _supabase
          .from('enrollments')
          .select()
          .eq('email', email)
          .eq('course', courseTitle);
      
      // Filter for PAID status in-memory if column exists in results
      final results = List<Map<String, dynamic>>.from(response);
      return results.any((r) => r['payment_status'] == 'PAID' || r['status'] == 'PAID');
    } catch (e) {
      // Fallback: just check if enrollment exists regardless of payment status
      try {
        final response = await _supabase
            .from('enrollments')
            .select()
            .eq('email', email)
            .eq('course', courseTitle)
            .maybeSingle();
        return response != null;
      } catch (_) {
        return false;
      }
    }
  }

  /// Get all enrollments for a user
  Future<List<Map<String, dynamic>>> getUserEnrollments(String email) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select()
          .eq('email', email);
      
      // Filter for PAID in-memory to avoid column-missing errors
      final results = List<Map<String, dynamic>>.from(response);
      return results.where((r) => 
        r['payment_status'] == 'PAID' || r['status'] == 'PAID' || !r.containsKey('payment_status')
      ).toList();
    } catch (e) {
      // Absolute fallback
      try {
        final response = await _supabase
            .from('enrollments')
            .select()
            .eq('email', email);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
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

  /// Save pending enrollment to Supabase
  Future<void> savePendingEnrollment(Map<String, dynamic> enrollmentData) async {
    await _supabase.from('enrollments').upsert([
      {
        ...enrollmentData,
        'payment_status': 'PENDING',
        'enrolled_at': DateTime.now().toIso8601String(),
      }
    ], onConflict: 'payment_id');
  }

  /// Confirm payment success in Supabase
  Future<void> confirmPayment(String orderId) async {
    await _supabase
        .from('enrollments')
        .update({'payment_status': 'PAID', 'enrolled_at': DateTime.now().toIso8601String()})
        .eq('payment_id', orderId);
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

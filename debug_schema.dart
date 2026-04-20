import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Initialize Supabase (copy from main.dart)
  await Supabase.initialize(
    url: 'https://othxceezbpfiauaevibt.supabase.co',
    anonKey: 'sb_publishable_ki8a43mdYzPTaypjvfBNFw_caZ1fTyv',
  );

  final client = Supabase.instance.client;
  
  try {
    final response = await client.from('enrollments').select().limit(1);
    if (response.isNotEmpty) {
      print('Columns in enrollments: ${response.first.keys}');
    } else {
      print('No records in enrollments to inspect columns.');
    }
  } catch (e) {
    print('Error inspecting table: $e');
  }
  exit(0);
}

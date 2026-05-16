import 'package:flutter/material.dart';

class Course {
  final String title;
  final String description;
  final String imageUrl;
  final String slug;
  final String category;
  final Color categoryColor;
  final String duration;
  final String level;
  final double rating;
  final String price;
  final List<String> highlights;
  final String instructorName;
  final String instructorImage;
  final int totalReviews;
  final bool isBestseller;
  final List<String> syllabus;
  final double govtPrice;
  final double pvtPrice;
  final double jobPrice;
  final bool isLegacyPricing;

  static const List<String> internshipSlugs = [
    "autocad-2d-3d-design",
    "java-programming",
    "python-programming",
    "data-science",
    "artificial-intelligence",
    "matlab-scientific-computing",
    "android-ios-mobile-development",
    "iot-embedded",
    "revit-bim",
    "solidworks",
    "catia",
    "sketchup",
    "etabs",
    "general"
  ];

  bool get isInternship => internshipSlugs.contains(slug);

  Course({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.slug,
    required this.category,
    required this.categoryColor,
    this.duration = '12 Hours',
    this.level = 'Beginner',
    this.rating = 4.8,
    this.price = 'Free',
    this.highlights = const [],
    this.instructorName = 'NLITedu Official',
    this.instructorImage = 'assets/app_logo.png',
    this.totalReviews = 1200,
    this.isBestseller = false,
    this.syllabus = const [],
    this.govtPrice = 0,
    this.pvtPrice = 0,
    this.jobPrice = 0,
    this.isLegacyPricing = false,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    // Map category to color
    Color catColor = Colors.blue;
    String category = (map['category'] ?? 'General').toString().toUpperCase();
    if (category.contains('DESIGN')) catColor = Colors.orange;
    if (category.contains('PROGRAMMING')) catColor = Colors.red;
    if (category.contains('DATA SCIENCE')) catColor = Colors.blue;
    if (category.contains('ENGINEERING')) catColor = Colors.indigo;
    if (category.contains('MANAGEMENT')) catColor = Colors.green;

    // Helper to safely parse boolean
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return Course(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? map['image'] ?? '',
      slug: map['slug'] ?? '',
      category: map['category'] ?? 'General',
      categoryColor: catColor,
      duration: map['duration'] ?? '12 Hours',
      level: map['level'] ?? 'Beginner',
      rating: map['rating']?.toDouble() ?? 4.8,
      price: map['price_label'] ?? map['price'] ?? 'Free',
      highlights: map['highlights'] != null ? List<String>.from(map['highlights']) : const [],
      instructorName: map['instructor_name'] ?? map['instructorName'] ?? 'NLITedu Official',
      instructorImage: map['instructor_image'] ?? map['instructorImage'] ?? 'assets/app_logo.png',
      totalReviews: map['totalReviews'] ?? 1200,
      isBestseller: parseBool(map['is_bestseller'] ?? map['isBestseller']),
      syllabus: map['syllabus'] != null ? List<String>.from(map['syllabus'] is List ? map['syllabus'] : []) : const [],
      govtPrice: (map['govt_price'] ?? 0).toDouble(),
      pvtPrice: (map['pvt_price'] ?? 0).toDouble(),
      jobPrice: (map['job_price'] ?? 0).toDouble(),
      isLegacyPricing: parseBool(map['is_legacy_pricing']),
    );
  }
}

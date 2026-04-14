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
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image'] ?? '',
      slug: map['slug'] ?? '',
      category: map['category'] ?? 'General',
      categoryColor: map['categoryColor'] ?? Colors.blue,
      duration: map['duration'] ?? '12 Hours',
      level: map['level'] ?? 'Beginner',
      rating: map['rating']?.toDouble() ?? 4.8,
      price: map['price'] ?? 'Free',
    );
  }
}

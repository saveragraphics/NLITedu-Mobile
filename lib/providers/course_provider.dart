import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../core/utils/supabase_utils.dart';

/// Provider that fetches courses dynamically from Supabase.
/// This allows the app to stay updated without code changes.
/// Provider that fetches courses in real-time from Supabase.
/// This allows the app to stay updated instantly without manual refresh.
final courseProvider = StreamProvider<List<Course>>((ref) {
  final supabase = Supabase.instance.client;
  
  // Create a stream from the 'courses' table using retryStreamWithAuth
  return retryStreamWithAuth<List<Course>>(() => supabase
      .from('courses')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((data) {
        if (data.isEmpty) return staticCourses;
        return data.map((map) => Course.fromMap(map)).toList();
      }));
});

/// Hardcoded fallback list to ensure the app works even offline or during migration.
final List<Course> staticCourses = [
  Course(
    title: "AutoCAD",
    slug: "autocad-2d-3d-design",
    description: "Master industry-standard AutoCAD tools for precise 2D drafting and 3D modeling essential for architects, engineers, and designers.",
    imageUrl: "https://www.nlitedu.com/fontimage/autocad.png",
    category: "DESIGN",
    categoryColor: Colors.orange,
    duration: "9 Months",
    level: "Intermediate",
    rating: 4.9,
    price: "₹999*",
    isBestseller: true,
    highlights: [
      "2D Drafting and 3D Modeling",
      "Industry-standard AutoCAD workflow",
      "Project-based learning for real-world design",
      "Layout, annotation, and dimensioning",
      "Live internship project included",
      "Industry-recognized NLIT certification",
    ],
    instructorName: "Ar. Rahul Sharma",
    instructorImage: "https://ui-avatars.com/api/?name=Rahul+Sharma&background=6366f1&color=fff&format=png",
    totalReviews: 1250,
    syllabus: [
      "Introduction to AutoCAD Interface & Navigation",
      "Drawing & Modification Tools (Line, Arc, Trim, Fillet)",
      "Layers, Blocks & Hatching",
      "Dimensioning & Annotations",
      "3D Modeling: Wireframe, Surface & Solid",
      "Rendering & Visualization",
      "Plotting & Layout Setup",
      "Live Project: Architectural Floor Plan",
    ],
  ),
  Course(
    title: "Revit Building Information Modeling (BIM)",
    slug: "revit-bim",
    description: "Learn BIM workflows and Revit software to create collaborative building designs with real-world applications.",
    imageUrl: "https://www.nlitedu.com/fontimage/revit.jpg",
    category: "DESIGN",
    categoryColor: Colors.orange,
    duration: "9 Months",
    level: "Intermediate",
    rating: 4.8,
    price: "₹999*",
    highlights: [
      "BIM modeling and collaboration",
      "Architecture, structure, and MEP support",
      "Live project-based Revit exercises",
      "Clash detection & coordination",
      "Industry-recognized NLIT certification",
      "Real-world construction documentation",
    ],
    instructorName: "Er. Amit Singh",
    instructorImage: "https://ui-avatars.com/api/?name=Amit+Singh&background=6366f1&color=fff&format=png",
    totalReviews: 850,
    syllabus: [
      "BIM Concepts & Revit Interface",
      "Walls, Doors, Windows & Components",
      "Floor Plans & Elevations",
      "Structural Modeling & Foundations",
      "MEP Systems (Mechanical/Electrical/Plumbing)",
      "Scheduling & Quantities",
      "Rendering & Walkthroughs",
      "Live Project: Residential Building Model",
    ],
  ),
  Course(
    title: "Java Programming",
    slug: "java-programming",
    description: "Develop robust enterprise-level applications by mastering Java fundamentals and advanced programming concepts.",
    imageUrl: "https://www.nlitedu.com/fontimage/java.png",
    category: "PROGRAMMING",
    categoryColor: Colors.red,
    duration: "9 Months",
    level: "Advanced",
    rating: 4.8,
    price: "₹999*",
    isBestseller: true,
    highlights: [
      "Core Java fundamentals & OOP",
      "Object-oriented design and data structures",
      "Build real applications with practical examples",
      "Multithreading & exception handling",
      "JDBC & database connectivity",
      "Industry-recognized NLIT certification",
    ],
    instructorName: "Sanjay Kumar",
    instructorImage: "https://ui-avatars.com/api/?name=Sanjay+Kumar&background=ef4444&color=fff&format=png",
    totalReviews: 2100,
    syllabus: [
      "Java Basics & Syntax",
      "OOP — Classes, Objects, Inheritance",
      "Polymorphism & Abstraction",
      "Exception Handling & File I/O",
      "Collections Framework",
      "Multithreading & Concurrency",
      "JDBC & Database Integration",
      "Capstone: Full-Stack Java App",
    ],
  ),
  Course(
    title: "Python for Data Science & AI",
    slug: "python-data-science-ai",
    description: "Dive into Python programming with a focus on data analysis, AI, and machine learning applications.",
    imageUrl: "https://www.nlitedu.com/fontimage/python.png",
    category: "DATA SCIENCE",
    categoryColor: Colors.blue,
    duration: "9 Months",
    level: "Beginner",
    rating: 4.7,
    price: "₹999*",
    highlights: [
      "Python programming for analytics",
      "Data visualization and machine learning",
      "Hands-on AI use cases with Python",
      "NumPy, Pandas & Matplotlib mastery",
      "Scikit-learn for ML models",
      "Industry-recognized NLIT certification",
    ],
    instructorName: "Dr. Anita Rao",
    instructorImage: "https://ui-avatars.com/api/?name=Anita+Rao&background=3b82f6&color=fff&format=png",
    totalReviews: 1800,
    syllabus: [
      "Python Fundamentals & Environment Setup",
      "Data Types, Control Flow & Functions",
      "NumPy for Numerical Computing",
      "Pandas for Data Manipulation",
      "Data Visualization with Matplotlib & Seaborn",
      "Intro to Machine Learning with Scikit-learn",
      "Regression & Classification Models",
      "Capstone: AI-Powered Data Analysis",
    ],
  ),
  Course(
    title: "MATLAB for Scientific Computing",
    slug: "matlab-scientific-computing",
    description: "Gain critical skills in MATLAB for data analysis, control systems, and engineering computations.",
    imageUrl: "https://www.nlitedu.com/fontimage/matlab2.png",
    category: "ENGINEERING",
    categoryColor: Colors.blue,
    duration: "9 Months",
    level: "Intermediate",
    rating: 4.6,
    price: "₹999*",
    highlights: [
      "MATLAB for engineering workflows",
      "Simulation and numerical computing",
      "Data analysis with MATLAB toolboxes",
      "Signal processing & control systems",
      "Simulink modeling",
      "Industry-recognized NLIT certification",
    ],
    instructorName: "Kiran Mazumdar",
    instructorImage: "https://ui-avatars.com/api/?name=Kiran+Mazumdar&background=3b82f6&color=fff&format=png",
    totalReviews: 650,
    syllabus: [
      "MATLAB Environment & Basics",
      "Matrices, Arrays & Operators",
      "Plotting & Data Visualization",
      "Script & Function Files",
      "Simulink Introduction",
      "Signal Processing Toolbox",
      "Control System Analysis",
      "Final Project: Engineering Simulation",
    ],
  ),
  Course(
    title: "NLIT Course Enrollment",
    slug: "general",
    description: "Select your course and fill out the enrollment form so we can reserve your seat and help you begin your learning journey.",
    imageUrl: "https://www.nlitedu.com/fontimage/java.png",
    category: "GENERAL",
    categoryColor: Colors.grey,
    duration: "Flexible",
    level: "All Levels",
    rating: 5.0,
    price: "Select Course",
    highlights: [
      "Choose from courses across design, development, AI, and engineering",
      "Secure admission with a simple online form",
      "Receive course guidance from the NLIT team",
    ],
    instructorName: "NLIT Team",
    instructorImage: "https://ui-avatars.com/api/?name=NLIT+Team&background=6366f1&color=fff&format=png",
    totalReviews: 5000,
    syllabus: ["General Admission"],
  ),
];

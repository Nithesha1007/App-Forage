import 'package:flutter/material.dart';

class TemplateModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String category;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> defaultScreens;
  final List<TemplateTable> defaultTables;
  final bool emailAuth;
  final bool googleAuth;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    required this.defaultScreens,
    required this.defaultTables,
    this.emailAuth = true,
    this.googleAuth = false,
  });

  String get primaryHex =>
      '#${primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';

  String get secondaryHex =>
      '#${secondaryColor.value.toRadixString(16).substring(2).toUpperCase()}';
}

class TemplateTable {
  final String name;
  final List<String> fields;
  const TemplateTable({required this.name, required this.fields});
}

// ── All built-in templates ────────────────────────────────────────────────────
class AppTemplates {
  AppTemplates._();

  static const List<String> categories = [
    'All',
    'Business',
    'Education',
    'Food',
    'Health',
    'Media',
    'Custom',
  ];

  static final List<TemplateModel> all = [
    // ── E-Commerce ──────────────────────────────────────────────────────────
    TemplateModel(
      id: 'ecommerce',
      name: 'E-Commerce',
      description:
          'Full shopping app with products, cart, checkout & order tracking.',
      emoji: '🛒',
      category: 'Business',
      primaryColor: const Color(0xFFFF6B35),
      secondaryColor: const Color(0xFFFF9F1C),
      emailAuth: true,
      googleAuth: true,
      defaultScreens: [
        'Home',
        'Products',
        'Cart',
        'Checkout',
        'Orders',
        'Profile',
      ],
      defaultTables: [
        TemplateTable(
          name: 'Products',
          fields: [
            'name',
            'price',
            'image',
            'category',
            'stock',
            'description',
          ],
        ),
        TemplateTable(
          name: 'Orders',
          fields: [
            'userId',
            'items',
            'total',
            'status',
            'address',
            'created_at',
          ],
        ),
        TemplateTable(
          name: 'Cart',
          fields: ['userId', 'productId', 'quantity'],
        ),
        TemplateTable(
          name: 'Users',
          fields: ['name', 'email', 'phone', 'address', 'created_at'],
        ),
      ],
    ),

    // ── School ──────────────────────────────────────────────────────────────
    TemplateModel(
      id: 'school',
      name: 'School',
      description: 'Manage attendance, grades, timetable and school notices.',
      emoji: '🏫',
      category: 'Education',
      primaryColor: const Color(0xFF3498DB),
      secondaryColor: const Color(0xFF2980B9),
      emailAuth: true,
      googleAuth: false,
      defaultScreens: [
        'Dashboard',
        'Attendance',
        'Grades',
        'Timetable',
        'Notices',
        'Profile',
      ],
      defaultTables: [
        TemplateTable(
          name: 'Students',
          fields: ['name', 'rollNo', 'class', 'email', 'phone', 'parent'],
        ),
        TemplateTable(
          name: 'Attendance',
          fields: ['studentId', 'date', 'status', 'subject'],
        ),
        TemplateTable(
          name: 'Grades',
          fields: ['studentId', 'subject', 'marks', 'grade', 'exam'],
        ),
        TemplateTable(
          name: 'Notices',
          fields: ['title', 'content', 'date', 'postedBy', 'priority'],
        ),
        TemplateTable(
          name: 'Timetable',
          fields: ['class', 'day', 'period', 'subject', 'teacher'],
        ),
      ],
    ),

    // ── Food Delivery ────────────────────────────────────────────────────────
    TemplateModel(
      id: 'food',
      name: 'Food Delivery',
      description:
          'Restaurant menu, ordering system and real-time delivery tracking.',
      emoji: '🍔',
      category: 'Food',
      primaryColor: const Color(0xFFE74C3C),
      secondaryColor: const Color(0xFFC0392B),
      emailAuth: true,
      googleAuth: true,
      defaultScreens: ['Home', 'Menu', 'Cart', 'Order', 'Track', 'Profile'],
      defaultTables: [
        TemplateTable(
          name: 'Menu',
          fields: [
            'name',
            'price',
            'image',
            'category',
            'description',
            'available',
          ],
        ),
        TemplateTable(
          name: 'Orders',
          fields: ['userId', 'items', 'total', 'status', 'address', 'rider'],
        ),
        TemplateTable(
          name: 'Restaurants',
          fields: ['name', 'logo', 'address', 'rating', 'cuisine', 'open'],
        ),
        TemplateTable(
          name: 'Reviews',
          fields: ['userId', 'restaurantId', 'rating', 'comment', 'date'],
        ),
      ],
    ),

    // ── Business CRM ─────────────────────────────────────────────────────────
    TemplateModel(
      id: 'crm',
      name: 'Business CRM',
      description: 'Manage contacts, leads, tasks and sales pipeline reports.',
      emoji: '💼',
      category: 'Business',
      primaryColor: const Color(0xFF9B59B6),
      secondaryColor: const Color(0xFF8E44AD),
      emailAuth: true,
      googleAuth: true,
      defaultScreens: [
        'Dashboard',
        'Contacts',
        'Leads',
        'Tasks',
        'Reports',
        'Settings',
      ],
      defaultTables: [
        TemplateTable(
          name: 'Contacts',
          fields: ['name', 'email', 'phone', 'company', 'status', 'source'],
        ),
        TemplateTable(
          name: 'Leads',
          fields: ['contactId', 'value', 'stage', 'assignee', 'closeDate'],
        ),
        TemplateTable(
          name: 'Tasks',
          fields: [
            'title',
            'assignee',
            'dueDate',
            'status',
            'priority',
            'notes',
          ],
        ),
        TemplateTable(
          name: 'Notes',
          fields: ['contactId', 'content', 'createdBy', 'created_at'],
        ),
      ],
    ),

    // ── Fitness ──────────────────────────────────────────────────────────────
    TemplateModel(
      id: 'fitness',
      name: 'Fitness',
      description: 'Track workouts, nutrition, body stats and weekly progress.',
      emoji: '💪',
      category: 'Health',
      primaryColor: const Color(0xFF00C896),
      secondaryColor: const Color(0xFF00A67E),
      emailAuth: true,
      googleAuth: true,
      defaultScreens: [
        'Dashboard',
        'Workouts',
        'Nutrition',
        'Progress',
        'Goals',
        'Profile',
      ],
      defaultTables: [
        TemplateTable(
          name: 'Workouts',
          fields: [
            'userId',
            'name',
            'date',
            'duration',
            'calories',
            'exercises',
          ],
        ),
        TemplateTable(
          name: 'Exercises',
          fields: ['name', 'category', 'sets', 'reps', 'weight', 'notes'],
        ),
        TemplateTable(
          name: 'Nutrition',
          fields: [
            'userId',
            'date',
            'meal',
            'calories',
            'protein',
            'carbs',
            'fat',
          ],
        ),
        TemplateTable(
          name: 'Progress',
          fields: ['userId', 'date', 'weight', 'bodyFat', 'chest', 'waist'],
        ),
      ],
    ),

    // ── Blog ─────────────────────────────────────────────────────────────────
    TemplateModel(
      id: 'blog',
      name: 'Blog',
      description:
          'Publish articles, manage categories and engage readers with comments.',
      emoji: '📰',
      category: 'Media',
      primaryColor: const Color(0xFFF39C12),
      secondaryColor: const Color(0xFFE67E22),
      emailAuth: true,
      googleAuth: true,
      defaultScreens: [
        'Home',
        'Articles',
        'Article Detail',
        'Categories',
        'Bookmarks',
        'Profile',
      ],
      defaultTables: [
        TemplateTable(
          name: 'Articles',
          fields: [
            'title',
            'content',
            'image',
            'authorId',
            'category',
            'tags',
            'published',
          ],
        ),
        TemplateTable(
          name: 'Categories',
          fields: ['name', 'slug', 'color', 'icon'],
        ),
        TemplateTable(
          name: 'Comments',
          fields: ['articleId', 'userId', 'content', 'likes', 'created_at'],
        ),
        TemplateTable(
          name: 'Bookmarks',
          fields: ['userId', 'articleId', 'saved_at'],
        ),
      ],
    ),

    // ── Blank ─────────────────────────────────────────────────────────────────
    TemplateModel(
      id: 'blank',
      name: 'Start from Scratch',
      description:
          'Blank canvas — build anything you imagine from the ground up.',
      emoji: '✨',
      category: 'Custom',
      primaryColor: const Color(0xFF6C63FF),
      secondaryColor: const Color(0xFF5A52E0),
      emailAuth: true,
      googleAuth: false,
      defaultScreens: ['Home'],
      defaultTables: [],
    ),
  ];

  static TemplateModel? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<TemplateModel> byCategory(String category) {
    if (category == 'All') return all;
    return all.where((t) => t.category == category).toList();
  }
}

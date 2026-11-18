import 'package:flutter/material.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/chapter.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String coverColorHex;
  final String description;
  final List<Chapter> chapters;
  final int totalChapters;
  final String category;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverColorHex,
    required this.description,
    required this.chapters,
    required this.totalChapters,
    this.category = 'Classic Literature',
  });

  Color get coverColor {
    try {
      return Color(int.parse(coverColorHex));
    } catch (_) {
      return AppColors.pepperRed;
    }
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverColorHex,
    String? description,
    List<Chapter>? chapters,
    int? totalChapters,
    String? category,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverColorHex: coverColorHex ?? this.coverColorHex,
      description: description ?? this.description,
      chapters: chapters ?? this.chapters,
      totalChapters: totalChapters ?? this.totalChapters,
      category: category ?? this.category,
    );
  }
}

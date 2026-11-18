import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ebook_app_desktop/models/book.dart';
import 'package:ebook_app_desktop/models/chapter.dart';

class BookService {
  BookService._();
  static final BookService instance = BookService._();

  List<Book>? _cachedBooks;

  Future<List<Book>> getAvailableBooks() async {
    if (_cachedBooks != null) return _cachedBooks!;

    try {
      final jsonString = await rootBundle.loadString('assets/books/books.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedBooks = jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        final chaptersRaw = (map['chapters'] as List<dynamic>?) ?? [];
        final chapters = chaptersRaw.map((c) => Chapter.fromMap(c as Map<String, dynamic>)).toList();

        return Book(
          id: map['id'] as String,
          title: map['title'] as String,
          author: map['author'] as String,
          coverColorHex: map['coverColorHex'] as String? ?? '0xFFC41E3A',
          description: map['description'] as String? ?? '',
          category: map['category'] as String? ?? 'Fiction',
          chapters: chapters,
          totalChapters: (map['totalChapters'] as int?) ?? chapters.length,
        );
      }).toList();

      return _cachedBooks!;
    } catch (e) {
      return [];
    }
  }

  Future<Book?> getBookById(String id) async {
    final books = await getAvailableBooks();
    try {
      return books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}


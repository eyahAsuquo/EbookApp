import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ebook_app/models/word_definition.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'ebook_dictionary.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT UNIQUE COLLATE NOCASE,
            phonetic TEXT,
            part_of_speech TEXT,
            definition TEXT,
            example TEXT,
            synonyms TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_words_word ON words(word COLLATE NOCASE)
        ''');

        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT UNIQUE COLLATE NOCASE,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE reading_progress (
            book_id TEXT PRIMARY KEY,
            chapter_index INTEGER,
            scroll_offset REAL,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  /// Seeds dictionary in batches while reporting progress to the UI
  Future<void> initializeAndSeedDictionary({
    void Function(double progress, String status)? onProgress,
  }) async {
    final db = await database;

    onProgress?.call(0.05, 'Checking local dictionary database...');

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count > 0) {
      onProgress?.call(1.0, 'Offline dictionary ready ($count words indexed)');
      return;
    }

    onProgress?.call(0.15, 'Unpacking offline vocabulary assets...');

    final rawJson = await rootBundle.loadString('assets/data/dictionary.json');
    final List<dynamic> jsonList = json.decode(rawJson);
    final total = jsonList.length;

    if (total == 0) {
      onProgress?.call(1.0, 'No words to seed.');
      return;
    }

    const batchSize = 25;
    int processed = 0;

    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize < total) ? i + batchSize : total;
      final batch = db.batch();

      for (int j = i; j < end; j++) {
        final item = jsonList[j] as Map<String, dynamic>;
        final wordDef = WordDefinition.fromJson(item);
        batch.insert(
          'words',
          wordDef.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      processed = end;
      final progressFraction = 0.2 + (0.8 * (processed / total));
      onProgress?.call(
        progressFraction,
        'Indexing vocabulary ($processed of $total words)...',
      );
      // Small pause to allow UI frames to breathe on low-end devices
      await Future.delayed(const Duration(milliseconds: 30));
    }

    onProgress?.call(1.0, 'Dictionary ready ($total words installed)');
  }

  /// Instant lookup for a word
  Future<WordDefinition?> lookupWord(String rawWord) async {
    final cleanWord = rawWord.trim().replaceAll(RegExp(r'[^\w\s-]'), '').toLowerCase();
    if (cleanWord.isEmpty) return null;

    final db = await database;

    // 1. Direct match
    List<Map<String, dynamic>> results = await db.query(
      'words',
      where: 'word = ? COLLATE NOCASE',
      whereArgs: [cleanWord],
      limit: 1,
    );

    // 2. If no direct match, try removing common suffixes like 's', 'ed', 'ing'
    if (results.isEmpty) {
      String stem = cleanWord;
      if (stem.endsWith('ing') && stem.length > 5) {
        stem = stem.substring(0, stem.length - 3);
      } else if (stem.endsWith('ed') && stem.length > 4) {
        stem = stem.substring(0, stem.length - 2);
      } else if (stem.endsWith('s') && stem.length > 3) {
        stem = stem.substring(0, stem.length - 1);
      }

      if (stem != cleanWord) {
        results = await db.query(
          'words',
          where: 'word = ? COLLATE NOCASE',
          whereArgs: [stem],
          limit: 1,
        );
      }
    }

    if (results.isEmpty) return null;

    final wordMap = results.first;
    final isBookmarked = await isWordBookmarked(wordMap['word'] as String);

    return WordDefinition.fromMap(wordMap, isBookmarked: isBookmarked);
  }

  /// Autocomplete search for words matching prefix
  Future<List<WordDefinition>> searchWords(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final db = await database;
    final results = await db.query(
      'words',
      where: 'word LIKE ? COLLATE NOCASE',
      whereArgs: ['$clean%'],
      orderBy: 'word ASC',
      limit: 30,
    );

    final bookmarks = await getBookmarkedWordsSet();

    return results.map((map) {
      final w = map['word'] as String;
      return WordDefinition.fromMap(map, isBookmarked: bookmarks.contains(w.toLowerCase()));
    }).toList();
  }

  /// Bookmark toggling
  Future<bool> toggleBookmark(String word) async {
    final clean = word.trim().toLowerCase();
    final db = await database;

    final existing = await db.query(
      'bookmarks',
      where: 'word = ? COLLATE NOCASE',
      whereArgs: [clean],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'bookmarks',
        where: 'word = ? COLLATE NOCASE',
        whereArgs: [clean],
      );
      return false; // now unbookmarked
    } else {
      await db.insert('bookmarks', {
        'word': clean,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true; // now bookmarked
    }
  }

  Future<bool> isWordBookmarked(String word) async {
    final clean = word.trim().toLowerCase();
    final db = await database;
    final res = await db.query(
      'bookmarks',
      where: 'word = ? COLLATE NOCASE',
      whereArgs: [clean],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<Set<String>> getBookmarkedWordsSet() async {
    final db = await database;
    final res = await db.query('bookmarks', columns: ['word']);
    return res.map((r) => (r['word'] as String).toLowerCase()).toSet();
  }

  Future<List<WordDefinition>> getBookmarkedWords() async {
    final db = await database;
    final raw = await db.rawQuery('''
      SELECT w.* FROM words w
      INNER JOIN bookmarks b ON LOWER(w.word) = LOWER(b.word)
      ORDER BY b.id DESC
    ''');

    return raw.map((m) => WordDefinition.fromMap(m, isBookmarked: true)).toList();
  }

  /// Reading progress persistence
  Future<void> saveReadingProgress(String bookId, int chapterIndex, double scrollOffset) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'book_id': bookId,
        'chapter_index': chapterIndex,
        'scroll_offset': scrollOffset,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    final db = await database;
    final res = await db.query(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }
}


import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/models/word_definition.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<String> _getDbPath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'ebook_dictionary.db');
  }

  Future<Database> _initDatabase() async {
    final dbPath = await _getDbPath();

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
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
      CREATE INDEX IF NOT EXISTS idx_words_word ON words(word COLLATE NOCASE)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE COLLATE NOCASE,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_progress (
        book_id TEXT PRIMARY KEY,
        chapter_index INTEGER,
        scroll_offset REAL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recent_pdfs (
        id TEXT PRIMARY KEY,
        file_path TEXT UNIQUE,
        file_name TEXT,
        file_size INTEGER,
        total_pages INTEGER,
        last_read_page INTEGER,
        last_opened_at TEXT
      )
    ''');
  }

  /// Seeds dictionary: if pre-indexed assets/data/dictionary.db exists, copies it directly.
  /// Otherwise falls back to JSON batch insertion.
  Future<void> initializeAndSeedDictionary({
    void Function(double progress, String status)? onProgress,
  }) async {
    final dbPath = await _getDbPath();
    final dbFile = File(dbPath);

    onProgress?.call(0.05, 'Checking offline vocabulary cache...');

    // If database already exists and has high word count (>= 50,000 words), it's already full
    if (await dbFile.exists()) {
      try {
        final existingDb = await database;
        await _createTables(existingDb);
        final countResult = await existingDb.rawQuery('SELECT COUNT(*) as count FROM words');
        final count = Sqflite.firstIntValue(countResult) ?? 0;
        if (count >= 50000) {
          onProgress?.call(1.0, 'Offline dictionary ready ($count words indexed)');
          return;
        }
      } catch (_) {}
    }

    // Try copying pre-built comprehensive SQLite database from assets
    try {
      onProgress?.call(0.15, 'Preparing full 100,000+ word offline dictionary...');

      final ByteData data = await rootBundle.load('assets/data/dictionary.db');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final totalBytes = bytes.length;

      // Close current db if open before overwriting
      if (_db != null && _db!.isOpen) {
        await _db!.close();
        _db = null;
      }

      final sink = dbFile.openWrite();
      const chunkSize = 256 * 1024; // 256 KB chunks
      int written = 0;

      for (int i = 0; i < totalBytes; i += chunkSize) {
        final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
        sink.add(bytes.sublist(i, end));
        written = end;
        final progress = 0.2 + (0.75 * (written / totalBytes));
        onProgress?.call(
          progress,
          'Unpacking dictionary (${(written / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB)...',
        );
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await sink.flush();
      await sink.close();

      // Reopen and ensure ancillary tables exist
      final db = await database;
      await _createTables(db);

      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM words');
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      onProgress?.call(1.0, 'Offline dictionary ready ($count words indexed)');
      return;
    } catch (e) {
      // Fallback to JSON batch seeding if .db asset could not be read
      onProgress?.call(0.2, 'Extracting fallback vocabulary data...');
      await _seedFromJson(onProgress);
    }
  }

  Future<void> _seedFromJson(void Function(double progress, String status)? onProgress) async {
    final db = await database;
    await _createTables(db);

    try {
      final rawJson = await rootBundle.loadString('assets/data/dictionary.json');
      final List<dynamic> jsonList = json.decode(rawJson);
      final total = jsonList.length;

      if (total == 0) {
        onProgress?.call(1.0, 'No words to seed.');
        return;
      }

      const batchSize = 50;
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
        final progress = 0.2 + (0.8 * (processed / total));
        onProgress?.call(
          progress,
          'Indexing vocabulary ($processed of $total words)...',
        );
        await Future.delayed(const Duration(milliseconds: 15));
      }

      onProgress?.call(1.0, 'Dictionary ready ($total words installed)');
    } catch (_) {
      onProgress?.call(1.0, 'Dictionary initialized');
    }
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

    // 2. If no direct match, try removing common suffixes like 's', 'ed', 'ing', 'ly'
    if (results.isEmpty) {
      String stem = cleanWord;
      if (stem.endsWith('ing') && stem.length > 5) {
        stem = stem.substring(0, stem.length - 3);
      } else if (stem.endsWith('ed') && stem.length > 4) {
        stem = stem.substring(0, stem.length - 2);
      } else if (stem.endsWith('ly') && stem.length > 4) {
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

  /// Recent PDFs persistence
  Future<void> saveOrUpdateRecentPdf(RecentPdf pdf) async {
    final db = await database;
    await db.insert(
      'recent_pdfs',
      pdf.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecentPdf>> getRecentPdfs() async {
    final db = await database;
    final results = await db.query(
      'recent_pdfs',
      orderBy: 'last_opened_at DESC',
      limit: 50,
    );
    return results.map((m) => RecentPdf.fromMap(m)).toList();
  }

  Future<void> updatePdfLastReadPage(String id, int page) async {
    final db = await database;
    await db.update(
      'recent_pdfs',
      {
        'last_read_page': page,
        'last_opened_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeRecentPdf(String id) async {
    final db = await database;
    await db.delete(
      'recent_pdfs',
      where: 'id = ?',
      whereArgs: [id],
    );
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

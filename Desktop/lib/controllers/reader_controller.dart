import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_app_desktop/models/book.dart';
import 'package:ebook_app_desktop/models/chapter.dart';
import 'package:ebook_app_desktop/models/reader_settings.dart';
import 'package:ebook_app_desktop/services/database_service.dart';

class ReaderController extends ChangeNotifier {
  Book? _currentBook;
  int _currentChapterIndex = 0;
  ReaderSettings _settings = const ReaderSettings();
  bool _isLoading = false;

  Book? get currentBook => _currentBook;
  int get currentChapterIndex => _currentChapterIndex;
  ReaderSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Chapter? get currentChapter {
    if (_currentBook == null || _currentBook!.chapters.isEmpty) return null;
    if (_currentChapterIndex < 0 || _currentChapterIndex >= _currentBook!.chapters.length) {
      return _currentBook!.chapters.first;
    }
    return _currentBook!.chapters[_currentChapterIndex];
  }

  static const String _prefFontSizeKey = 'reader_font_size';
  static const String _prefThemeModeKey = 'reader_theme_mode';
  static const String _prefFontFamilyKey = 'reader_font_family';

  ReaderController() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFontSize = prefs.getDouble(_prefFontSizeKey) ?? 17.0;
    final savedThemeIndex = prefs.getInt(_prefThemeModeKey) ?? ReaderThemeMode.sepia.index;
    final savedFontIndex = prefs.getInt(_prefFontFamilyKey) ?? ReaderFontFamily.serif.index;

    _settings = ReaderSettings(
      fontSize: savedFontSize,
      themeMode: ReaderThemeMode.values[savedThemeIndex],
      fontFamily: ReaderFontFamily.values[savedFontIndex],
    );
    notifyListeners();
  }

  Future<void> openBook(Book book, {int chapterIndex = 0}) async {
    _isLoading = true;
    _currentBook = book;
    _currentChapterIndex = chapterIndex;
    notifyListeners();

    // Check if there was saved reading progress
    final savedProgress = await DatabaseService.instance.getReadingProgress(book.id);
    if (savedProgress != null) {
      final savedChapter = (savedProgress['chapter_index'] as int?) ?? 0;
      if (savedChapter >= 0 && savedChapter < book.chapters.length) {
        _currentChapterIndex = savedChapter;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void goToChapter(int index) {
    if (_currentBook == null) return;
    if (index >= 0 && index < _currentBook!.chapters.length) {
      _currentChapterIndex = index;
      notifyListeners();
      _saveProgress();
    }
  }

  void nextChapter() {
    if (_currentBook != null && _currentChapterIndex + 1 < _currentBook!.chapters.length) {
      goToChapter(_currentChapterIndex + 1);
    }
  }

  void previousChapter() {
    if (_currentBook != null && _currentChapterIndex > 0) {
      goToChapter(_currentChapterIndex - 1);
    }
  }

  Future<void> updateFontSize(double size) async {
    _settings = _settings.copyWith(fontSize: size);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefFontSizeKey, size);
  }

  Future<void> updateThemeMode(ReaderThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeModeKey, mode.index);
  }

  Future<void> updateFontFamily(ReaderFontFamily family) async {
    _settings = _settings.copyWith(fontFamily: family);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFontFamilyKey, family.index);
  }

  void recordScroll(double offset) {
    _saveProgress(scrollOffset: offset);
  }

  void _saveProgress({double scrollOffset = 0.0}) {
    if (_currentBook != null) {
      DatabaseService.instance.saveReadingProgress(
        _currentBook!.id,
        _currentChapterIndex,
        scrollOffset,
      );
    }
  }
}


import 'package:flutter/foundation.dart';
import 'package:ebook_app/models/word_definition.dart';
import 'package:ebook_app/services/database_service.dart';

class DictionaryController extends ChangeNotifier {
  WordDefinition? _activeDefinition;
  bool _isLoading = false;
  String? _lookupError;

  List<WordDefinition> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  List<WordDefinition> _bookmarkedWords = [];
  bool _isLoadingBookmarks = false;

  WordDefinition? get activeDefinition => _activeDefinition;
  bool get isLoading => _isLoading;
  String? get lookupError => _lookupError;

  List<WordDefinition> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  List<WordDefinition> get bookmarkedWords => _bookmarkedWords;
  bool get isLoadingBookmarks => _isLoadingBookmarks;

  /// Look up a word from text or selection
  Future<WordDefinition?> lookupWord(String word) async {
    _isLoading = true;
    _lookupError = null;
    notifyListeners();

    try {
      final definition = await DatabaseService.instance.lookupWord(word);
      if (definition != null) {
        _activeDefinition = definition;
      } else {
        _activeDefinition = WordDefinition(
          word: word.trim(),
          phonetic: '',
          partOfSpeech: 'not found',
          definition: 'No offline definition found for "$word". You can explore our offline vocabulary or bookmark it for future review.',
          isBookmarked: await DatabaseService.instance.isWordBookmarked(word),
        );
      }
      _isLoading = false;
      notifyListeners();
      return _activeDefinition;
    } catch (e) {
      _lookupError = 'Failed to lookup word: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearActiveDefinition() {
    _activeDefinition = null;
    _lookupError = null;
    notifyListeners();
  }

  /// Search words for autocomplete
  Future<void> search(String query) async {
    _currentQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await DatabaseService.instance.searchWords(query);
      _searchResults = results;
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Toggle bookmark for any word
  Future<void> toggleBookmark(WordDefinition wordDef) async {
    final newStatus = await DatabaseService.instance.toggleBookmark(wordDef.word);

    // Update active definition state if open
    if (_activeDefinition != null &&
        _activeDefinition!.word.toLowerCase() == wordDef.word.toLowerCase()) {
      _activeDefinition = _activeDefinition!.copyWith(isBookmarked: newStatus);
    }

    // Update search results list if present
    _searchResults = _searchResults.map((item) {
      if (item.word.toLowerCase() == wordDef.word.toLowerCase()) {
        return item.copyWith(isBookmarked: newStatus);
      }
      return item;
    }).toList();

    // Reload bookmarks list
    await loadBookmarks();
    notifyListeners();
  }

  Future<void> loadBookmarks() async {
    _isLoadingBookmarks = true;
    notifyListeners();

    try {
      _bookmarkedWords = await DatabaseService.instance.getBookmarkedWords();
    } catch (e) {
      _bookmarkedWords = [];
    } finally {
      _isLoadingBookmarks = false;
      notifyListeners();
    }
  }
}


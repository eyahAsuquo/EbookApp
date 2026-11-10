import 'package:flutter/foundation.dart';
import 'package:ebook_app/models/book.dart';
import 'package:ebook_app/services/book_service.dart';

class LibraryController extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await BookService.instance.getAvailableBooks();
    } catch (e) {
      _errorMessage = 'Failed to load library: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


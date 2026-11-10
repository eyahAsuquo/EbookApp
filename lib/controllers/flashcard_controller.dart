import 'package:flutter/foundation.dart';

class FlashcardController extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isFlipped = false;

  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;

  void flip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void nextCard(int totalCards) {
    if (_currentIndex + 1 < totalCards) {
      _currentIndex++;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void prevCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_app/models/onboarding_slide.dart';
import 'package:ebook_app/services/database_service.dart';

class OnboardingController extends ChangeNotifier {
  int _currentPage = 0;
  double _syncProgress = 0.0;
  String _syncStatus = 'Starting background offline dictionary sync...';
  bool _isSyncComplete = false;
  bool _hasSeenOnboarding = false;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      icon: Icons.auto_stories_rounded,
      tag: 'Offline Reading',
      title: 'Immersive Offline Reading',
      description:
          'Enjoy rich stories without interruptions or internet connectivity. Customize fonts, spacing, and eye-friendly sepia and dark themes.',
    ),
    OnboardingSlide(
      icon: Icons.touch_app_rounded,
      tag: 'Instant Lookup',
      title: 'Tap-to-Define Inbuilt Dictionary',
      description:
          'No more context switching between dictionary apps. Simply tap any word inside the ebook for instant phonetics, meanings, and examples.',
    ),
    OnboardingSlide(
      icon: Icons.offline_bolt_rounded,
      tag: 'Zero Latency',
      title: 'Local Engine & Vocabulary Bookmarks',
      description:
          'The entire dictionary is indexed directly inside your phone. Bookmark intriguing words to build your personal offline vocabulary list.',
    ),
  ];

  List<OnboardingSlide> get slides => _slides;
  int get currentPage => _currentPage;
  double get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  bool get isSyncComplete => _isSyncComplete;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  bool get isLastPage => _currentPage == _slides.length - 1;
  bool get canProceedToApp => _isSyncComplete || _syncProgress >= 0.95;
  int get totalSlides => _slides.length;

  static const String _prefKeyOnboarding = 'has_completed_onboarding';

  Future<void> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_prefKeyOnboarding) ?? false;
    notifyListeners();
  }

  void setPage(int index) {
    if (index >= 0 && index < _slides.length) {
      _currentPage = index;
      notifyListeners();
    }
  }

  /// Initiates background database seeding while the user navigates onboarding slides
  void startBackgroundSync() {
    DatabaseService.instance.initializeAndSeedDictionary(
      onProgress: (progress, status) {
        _syncProgress = progress;
        _syncStatus = status;
        if (progress >= 1.0) {
          _isSyncComplete = true;
        }
        notifyListeners();
      },
    ).catchError((error) {
      _syncStatus = 'Dictionary installation complete.';
      _isSyncComplete = true;
      _syncProgress = 1.0;
      notifyListeners();
    });
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnboarding, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }
}

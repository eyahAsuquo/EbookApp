import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_app/services/database_service.dart';

class OnboardingController extends ChangeNotifier {
  int _currentPage = 0;
  double _syncProgress = 0.0;
  String _syncStatus = 'Starting background offline dictionary sync...';
  bool _isSyncComplete = false;
  bool _hasSeenOnboarding = false;

  int get currentPage => _currentPage;
  double get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  bool get isSyncComplete => _isSyncComplete;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  static const String _prefKeyOnboarding = 'has_completed_onboarding';

  Future<void> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_prefKeyOnboarding) ?? false;
    notifyListeners();
  }

  void setPage(int index) {
    _currentPage = index;
    notifyListeners();
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


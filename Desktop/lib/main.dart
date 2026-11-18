import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/controllers/flashcard_controller.dart';
import 'package:ebook_app_desktop/controllers/library_controller.dart';
import 'package:ebook_app_desktop/controllers/onboarding_controller.dart';
import 'package:ebook_app_desktop/controllers/reader_controller.dart';
import 'package:ebook_app_desktop/core/theme/app_theme.dart';
import 'package:ebook_app_desktop/services/database_service.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite FFI engine
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-seed offline 102,000+ words dictionary in background
  DatabaseService.instance.initializeAndSeedDictionary().catchError((_) {});

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OnboardingController()..checkOnboardingStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => DictionaryController(),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FlashcardController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderController(),
        ),
      ],
      child: const PepperReaderDesktopApp(),
    ),
  );
}

class PepperReaderDesktopApp extends StatelessWidget {
  const PepperReaderDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper Reader - Desktop Edition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DesktopShellScreen(),
    );
  }
}

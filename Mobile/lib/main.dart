import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ebook_app/controllers/dictionary_controller.dart';
import 'package:ebook_app/controllers/flashcard_controller.dart';
import 'package:ebook_app/controllers/library_controller.dart';
import 'package:ebook_app/controllers/onboarding_controller.dart';
import 'package:ebook_app/controllers/reader_controller.dart';
import 'package:ebook_app/core/theme/app_theme.dart';
import 'package:ebook_app/views/library/library_screen.dart';
import 'package:ebook_app/views/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop SQLite FFI support
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
          create: (_) => ReaderController(),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FlashcardController(),
        ),
      ],
      child: const EbookReaderApp(),
    ),
  );
}

class EbookReaderApp extends StatelessWidget {
  const EbookReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<OnboardingController>(
        builder: (context, onboardingController, child) {
          if (onboardingController.hasSeenOnboarding) {
            return const LibraryScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}

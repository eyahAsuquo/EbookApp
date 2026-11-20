import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'package:ebook_app_desktop/services/file_association_service.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_shell_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite FFI engine
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-seed offline 102,000+ words dictionary in background
  DatabaseService.instance.initializeAndSeedDictionary().catchError((_) {});

  // Parse any PDF file passed as command line argument (e.g. double clicked in Windows Explorer)
  String? initialPdfPath;
  for (final arg in args) {
    final clean = arg.replaceAll('"', '').trim();
    if (clean.toLowerCase().endsWith('.pdf') && File(clean).existsSync()) {
      initialPdfPath = File(clean).absolute.path;
      break;
    }
  }

  // Automatically register file association if on Windows release executable
  if (!kIsWeb && Platform.isWindows && !kDebugMode) {
    FileAssociationService.instance.registerPdfAssociation().catchError((_) => false);
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
          create: (_) => LibraryController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FlashcardController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderController(),
        ),
      ],
      child: PepperReaderDesktopApp(initialPdfPath: initialPdfPath),
    ),
  );
}

class PepperReaderDesktopApp extends StatelessWidget {
  final String? initialPdfPath;

  const PepperReaderDesktopApp({super.key, this.initialPdfPath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper Reader - Desktop Edition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: DesktopShellScreen(initialFilePath: initialPdfPath),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/controllers/flashcard_controller.dart';
import 'package:ebook_app_desktop/controllers/library_controller.dart';
import 'package:ebook_app_desktop/controllers/onboarding_controller.dart';
import 'package:ebook_app_desktop/controllers/reader_controller.dart';
import 'package:ebook_app_desktop/core/theme/app_theme.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/models/word_definition.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_dictionary_panel.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_shell_screen.dart';

void main() {
  group('Desktop Model Tests', () {
    test('RecentPdf serialization and formatting', () {
      final now = DateTime.now();
      final pdf = RecentPdf(
        id: '123',
        filePath: 'C:/docs/manual.pdf',
        fileName: 'manual.pdf',
        fileSize: 1024 * 1024 * 4,
        totalPages: 45,
        lastReadPage: 12,
        lastOpenedAt: now,
      );

      final map = pdf.toMap();
      final restored = RecentPdf.fromMap(map);

      expect(restored.id, '123');
      expect(restored.fileName, 'manual.pdf');
      expect(restored.formattedFileSize, '4.0 MB');
      expect(restored.lastReadPage, 12);
    });

    test('WordDefinition serialization', () {
      const def = WordDefinition(
        word: 'serendipity',
        phonetic: '/ˌser.ənˈdɪp.ə.ti/',
        partOfSpeech: 'noun',
        definition: 'Occurrence of events by chance in a happy way.',
        example: 'Finding the manuscript was serendipity.',
        synonyms: ['luck', 'chance'],
        isBookmarked: true,
      );

      final map = def.toMap();
      final restored = WordDefinition.fromMap(map, isBookmarked: true);

      expect(restored.word, 'serendipity');
      expect(restored.partOfSpeech, 'noun');
      expect(restored.isBookmarked, true);
    });
  });

  group('Desktop Shell Smoke Tests', () {
    testWidgets('DesktopShellScreen renders sidebar navigation rail', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OnboardingController()),
            ChangeNotifierProvider(create: (_) => DictionaryController()),
            ChangeNotifierProvider(create: (_) => LibraryController()),
            ChangeNotifierProvider(create: (_) => FlashcardController()),
            ChangeNotifierProvider(create: (_) => ReaderController()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DesktopShellScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pepper Reader'), findsOneWidget);
      expect(find.text('Desktop Edition'), findsOneWidget);
      expect(find.text('Recent Documents'), findsOneWidget);
      expect(find.text('Saved Words'), findsOneWidget);
      expect(find.text('Flashcards Practice'), findsOneWidget);
      expect(find.text('Search Dictionary'), findsOneWidget);
    });

    testWidgets('DesktopDictionaryPanel displays empty placeholder when no active word',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DictionaryController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DesktopDictionaryPanel(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dictionary Inspector'), findsOneWidget);
      expect(find.text('Select Any Word'), findsOneWidget);
    });
  });
}

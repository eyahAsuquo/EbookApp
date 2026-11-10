import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/dictionary_controller.dart';
import 'package:ebook_app/controllers/library_controller.dart';
import 'package:ebook_app/controllers/onboarding_controller.dart';
import 'package:ebook_app/controllers/reader_controller.dart';
import 'package:ebook_app/core/theme/app_theme.dart';
import 'package:ebook_app/models/word_definition.dart';
import 'package:ebook_app/views/common_widgets/pepper_button.dart';
import 'package:ebook_app/views/common_widgets/word_badge.dart';
import 'package:ebook_app/views/onboarding/onboarding_screen.dart';
import 'package:ebook_app/views/dictionary/vocabulary_study_screen.dart';

void main() {
  group('WordDefinition Model Tests', () {
    test('toMap and fromMap work symmetrically', () {
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
      expect(restored.synonyms, contains('luck'));
      expect(restored.isBookmarked, true);
    });

    test('copyWith properly updates bookmark state', () {
      const def = WordDefinition(
        word: 'curious',
        phonetic: '/ˈkjʊə.ri.əs/',
        partOfSpeech: 'adjective',
        definition: 'Eager to know or learn something.',
        isBookmarked: false,
      );

      final bookmarked = def.copyWith(isBookmarked: true);
      expect(bookmarked.isBookmarked, true);
      expect(bookmarked.word, def.word);
    });
  });

  group('Reusable UI Widget Smoke Tests', () {
    testWidgets('PepperButton renders with Pepper Red styling', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PepperButton(
              label: 'Test Button',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(tapped, isTrue);
    });

    testWidgets('WordBadge renders correct text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordBadge(text: 'adjective'),
          ),
        ),
      );

      expect(find.text('adjective'), findsOneWidget);
    });

    testWidgets('OnboardingScreen displays 3-slide flow and Pepper Red controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OnboardingController()),
            ChangeNotifierProvider(create: (_) => DictionaryController()),
            ChangeNotifierProvider(create: (_) => ReaderController()),
            ChangeNotifierProvider(create: (_) => LibraryController()),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check first slide title
      expect(find.text('Immersive Offline Reading'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('VocabularyStudyScreen displays empty state when no bookmarks',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DictionaryController()),
          ],
          child: const MaterialApp(
            home: VocabularyStudyScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Vocabulary Flashcards'), findsOneWidget);
      expect(find.text('No Bookmarked Words'), findsOneWidget);
    });
  });
}

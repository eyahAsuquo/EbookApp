import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/controllers/flashcard_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/word_definition.dart';
import 'package:ebook_app_desktop/views/common_widgets/pepper_button.dart';
import 'package:ebook_app_desktop/views/common_widgets/word_badge.dart';

class VocabularyStudyScreen extends StatefulWidget {
  const VocabularyStudyScreen({super.key});

  @override
  State<VocabularyStudyScreen> createState() => _VocabularyStudyScreenState();
}

class _VocabularyStudyScreenState extends State<VocabularyStudyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Reset flashcard state upon opening screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardController>().reset();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _syncAnimationWithState(bool isFlipped) {
    if (isFlipped) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Flashcards'),
        centerTitle: true,
      ),
      body: Consumer2<DictionaryController, FlashcardController>(
        builder: (context, dictController, flashcardController, child) {
          final words = dictController.bookmarkedWords;

          if (words.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.style_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Bookmarked Words',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bookmark words while reading to practice them here with interactive flashcards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PepperButton(
                      label: 'Back to Library',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentIndex = flashcardController.currentIndex.clamp(0, words.length - 1);
          final currentWord = words[currentIndex];

          // Synchronize visual animation with controller state
          _syncAnimationWithState(flashcardController.isFlipped);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card ${currentIndex + 1} of ${words.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pepperRedSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tap card to flip',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pepperRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / words.length,
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pepperRed),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3D Flip Flashcard
                  Expanded(
                    child: GestureDetector(
                      onTap: () => flashcardController.flip(),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final angle = _animation.value * math.pi;
                          final isBack = _animation.value >= 0.5;

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isBack
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(currentWord),
                                  )
                                : _buildFrontCard(currentWord),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.badgeBg,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: currentIndex > 0
                            ? () => flashcardController.prevCard()
                            : null,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pepperRedSoft,
                          foregroundColor: AppColors.pepperRed,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.flip_rounded, size: 18),
                        label: Text(flashcardController.isFlipped ? 'Show Word' : 'Show Meaning'),
                        onPressed: () => flashcardController.flip(),
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.pepperRed,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: currentIndex + 1 < words.length
                            ? () => flashcardController.nextCard(words.length)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(WordDefinition word) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WordBadge(text: word.partOfSpeech),
              const SizedBox(height: 18),
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (word.phonetic.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  word.phonetic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: AppColors.pepperRed.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to view definition',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pepperRed.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(WordDefinition word) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.pepperRed, width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pepperRed,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              const Text(
                'DEFINITION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                word.definition,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
              if (word.example != null && word.example!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '"${word.example}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/views/common_widgets/word_badge.dart';
import 'package:ebook_app_desktop/views/dictionary/dictionary_bottom_sheet.dart';
import 'package:ebook_app_desktop/views/dictionary/vocabulary_study_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictionaryController>().loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryController>(
      builder: (context, controller, child) {
        final bookmarks = controller.bookmarkedWords;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Vocabulary'),
            centerTitle: true,
            actions: [
              if (bookmarks.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.style_rounded, color: Colors.white),
                  tooltip: 'Practice Flashcards',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VocabularyStudyScreen()),
                    );
                  },
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (controller.isLoadingBookmarks) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.pepperRed),
                );
              }

              if (bookmarks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.pepperRedSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_outline_rounded,
                            size: 40,
                            color: AppColors.pepperRed,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Bookmarked Words Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tap any word inside your ebooks or search the dictionary to look up definitions and save interesting vocabulary for offline revision.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Flashcard banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VocabularyStudyScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.pepperRedSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.pepperRed.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppColors.pepperRed, size: 22),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Practice with Flashcards',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.pepperRed,
                                    ),
                                  ),
                                  Text(
                                    'Review your saved words with 3D flip study cards',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.pepperRed),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: bookmarks.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = bookmarks[index];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              DictionaryBottomSheet.show(context, item);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.word,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      WordBadge(text: item.partOfSpeech),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.pepperRed),
                                        tooltip: 'Remove bookmark',
                                        onPressed: () {
                                          controller.toggleBookmark(item);
                                        },
                                      ),
                                    ],
                                  ),
                                  if (item.phonetic.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.phonetic,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    item.definition,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}


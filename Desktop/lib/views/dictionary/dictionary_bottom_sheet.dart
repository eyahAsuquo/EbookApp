import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/word_definition.dart';
import 'package:ebook_app_desktop/views/common_widgets/word_badge.dart';

class DictionaryBottomSheet extends StatelessWidget {
  final WordDefinition definition;

  const DictionaryBottomSheet({
    super.key,
    required this.definition,
  });

  static Future<void> show(BuildContext context, WordDefinition definition) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DictionaryBottomSheet(definition: definition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Consumer<DictionaryController>(
      builder: (context, dictController, child) {
        // Use live active definition if updated (e.g. synonym tapped or bookmark toggled)
        final liveDef = (dictController.activeDefinition != null &&
                dictController.activeDefinition!.word.toLowerCase() == definition.word.toLowerCase())
            ? dictController.activeDefinition!
            : definition;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 8),
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // Scrollable Body (long text scrolls, short text stays compact at bottom)
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: mediaQuery.viewInsets.bottom + 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Word Title, Phonetic & Bookmark Button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      liveDef.word,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (liveDef.phonetic.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        liveDef.phonetic,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Bookmark Button
                              IconButton.filledTonal(
                                tooltip: liveDef.isBookmarked ? 'Remove Bookmark' : 'Bookmark Word',
                                style: IconButton.styleFrom(
                                  backgroundColor: liveDef.isBookmarked
                                      ? AppColors.gold.withValues(alpha: 0.18)
                                      : AppColors.badgeBg,
                                  foregroundColor: liveDef.isBookmarked
                                      ? AppColors.gold
                                      : AppColors.textSecondary,
                                ),
                                icon: Icon(
                                  liveDef.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  size: 24,
                                ),
                                onPressed: () {
                                  dictController.toggleBookmark(liveDef);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(milliseconds: 1400),
                                      backgroundColor: AppColors.textPrimary,
                                      content: Text(
                                        liveDef.isBookmarked
                                            ? 'Removed "${liveDef.word}" from saved words'
                                            : 'Saved "${liveDef.word}" to bookmarked vocabulary!',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Part of speech badge
                          WordBadge(text: liveDef.partOfSpeech),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 14),

                          // Definition
                          const Text(
                            'DEFINITION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            liveDef.definition,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Example Sentence
                          if (liveDef.example != null && liveDef.example!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.format_quote_rounded, size: 20, color: AppColors.pepperRed),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      liveDef.example!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Synonyms
                          if (liveDef.synonyms.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'SYNONYMS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: liveDef.synonyms.map((synonym) {
                                return ActionChip(
                                  label: Text(
                                    synonym,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  backgroundColor: AppColors.background,
                                  side: const BorderSide(color: AppColors.divider),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  onPressed: () async {
                                    final newDef = await dictController.lookupWord(synonym);
                                    if (newDef != null && context.mounted) {
                                      // The consumer will update liveDef smoothly!
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


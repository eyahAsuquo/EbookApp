import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/word_definition.dart';
import 'package:ebook_app_desktop/views/common_widgets/word_badge.dart';

class DesktopDictionaryPanel extends StatelessWidget {
  final VoidCallback? onClose;

  const DesktopDictionaryPanel({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryController>(
      builder: (context, dictController, child) {
        final def = dictController.activeDefinition;

        return Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              left: BorderSide(color: AppColors.divider, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(-3, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.pepperRedSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        size: 16,
                        color: AppColors.pepperRed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dictionary Inspector',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        tooltip: 'Hide Panel',
                        onPressed: onClose,
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: def == null
                    ? _buildEmptyState()
                    : _buildDefinitionContent(context, def, dictController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.pepperRedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 28,
                color: AppColors.pepperRed,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Any Word',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Double-click or highlight any word in the PDF on the left. Definitions, phonetics, and examples will appear here instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionContent(
    BuildContext context,
    WordDefinition def,
    DictionaryController dictController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word & Bookmark Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.word,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (def.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        def.phonetic,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: def.isBookmarked ? 'Remove Bookmark' : 'Bookmark Word',
                style: IconButton.styleFrom(
                  backgroundColor: def.isBookmarked
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : AppColors.badgeBg,
                  foregroundColor: def.isBookmarked ? AppColors.gold : AppColors.textSecondary,
                ),
                icon: Icon(
                  def.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                ),
                onPressed: () {
                  dictController.toggleBookmark(def);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Part of Speech
          WordBadge(text: def.partOfSpeech),
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
          const SizedBox(height: 8),
          Text(
            def.definition,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),

          // Example
          if (def.example != null && def.example!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '"${def.example}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],

          // Synonyms
          if (def.synonyms.isNotEmpty) ...[
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
              spacing: 6,
              runSpacing: 6,
              children: def.synonyms.map((syn) {
                return ActionChip(
                  label: Text(syn, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.divider),
                  onPressed: () => dictController.lookupWord(syn),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/reader_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/views/dictionary/dictionary_search_screen.dart';
import 'package:ebook_app/views/reader/widgets/reader_settings_sheet.dart';
import 'package:ebook_app/views/reader/widgets/reader_text_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      context.read<ReaderController>().recordScroll(_scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderController>(
      builder: (context, controller, child) {
        final book = controller.currentBook;
        final chapter = controller.currentChapter;
        final settings = controller.settings;

        if (book == null || chapter == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.pepperRed),
            ),
          );
        }

        final bg = settings.backgroundColor;
        final fg = settings.textColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            foregroundColor: fg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: fg),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                Text(
                  'Chapter ${controller.currentChapterIndex + 1} of ${book.totalChapters}',
                  style: TextStyle(
                    fontSize: 11,
                    color: fg.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search_rounded, color: fg),
                tooltip: 'Search Dictionary',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DictionarySearchScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.text_fields_rounded, color: fg),
                tooltip: 'Text & Theme Settings',
                onPressed: () => ReaderSettingsSheet.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Hint strip on how to use tap-to-define
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.pepperRed.withValues(alpha: 0.08),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 14, color: AppColors.pepperRed),
                    SizedBox(width: 6),
                    Text(
                      'Tip: Tap any word to view its offline definition',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pepperRed,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Reader Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter Title Header
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: settings.fontSize + 6,
                          fontWeight: FontWeight.w800,
                          color: fg,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.pepperRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interactive Reading Content
                      ReaderTextView(
                        content: chapter.content,
                        settings: settings,
                      ),

                      const SizedBox(height: 40),

                      // Bottom Chapter Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (controller.currentChapterIndex > 0)
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: AppColors.pepperRed),
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('Previous Chapter'),
                              onPressed: () {
                                _scrollController.jumpTo(0);
                                controller.previousChapter();
                              },
                            )
                          else
                            const SizedBox.shrink(),
                          if (controller.currentChapterIndex + 1 < book.totalChapters)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pepperRed,
                                foregroundColor: Colors.white,
                              ),
                              label: const Text('Next Chapter'),
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: () {
                                _scrollController.jumpTo(0);
                                controller.nextChapter();
                              },
                            )
                          else
                            const Chip(
                              label: Text('End of Book', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/library_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/services/intent_service.dart';
import 'package:ebook_app/views/common_widgets/pepper_button.dart';
import 'package:ebook_app/views/dictionary/bookmarks_screen.dart';
import 'package:ebook_app/views/dictionary/dictionary_search_screen.dart';
import 'package:ebook_app/views/library/widgets/recent_pdf_card.dart';
import 'package:ebook_app/views/reader/pdf_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LibraryController>().loadRecentPdfs();

      // Listen for incoming PDF files when app is already open
      IntentService.instance.initialize((path) {
        _openPdfFromPath(path);
      });

      // Handle PDF that triggered app launch
      final initialPath = await IntentService.instance.getInitialPdf();
      if (initialPath != null && initialPath.isNotEmpty && mounted) {
        _openPdfFromPath(initialPath);
      }
    });
  }

  void _openPdfFromPath(String path) async {
    final libraryController = context.read<LibraryController>();
    final pdf = await libraryController.openPdfFromPath(path);

    if (pdf != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(pdf: pdf),
        ),
      );
    }
  }

  void _pickAndOpenPdf() async {
    final libraryController = context.read<LibraryController>();
    final pdf = await libraryController.pickAndOpenPdf();

    if (pdf != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(pdf: pdf),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.pepperRedSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: AppColors.pepperRed,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Pepper Reader'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Dictionary',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DictionarySearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded, color: AppColors.pepperRed),
            tooltip: 'Saved Vocabulary',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.pepperRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('Open PDF'),
        onPressed: _pickAndOpenPdf,
      ),
      body: Consumer<LibraryController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pepperRed),
            );
          }

          final recents = controller.recentPdfs;

          if (recents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.pepperRedSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 44,
                        color: AppColors.pepperRed,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No PDF Documents Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Open any PDF from your device storage to start reading. Tap any word inside the document for instant offline definitions and phonetics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PepperButton(
                      label: 'Open PDF from Device',
                      icon: Icons.folder_open_rounded,
                      onPressed: _pickAndOpenPdf,
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Banner Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.pepperRed,
                          AppColors.pepperRedDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pepperRed.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '100% OFFLINE DICTIONARY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Interactive PDF Reader',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Highlight or tap any word in your PDFs for instant meanings, phonetics, and bookmarks.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.pepperRed,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 28),
                          tooltip: 'Open new PDF',
                          onPressed: _pickAndOpenPdf,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Default PDF App Helper Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final opened =
                          await IntentService.instance.openDefaultAppSettings();
                      if (!opened && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'To make Pepper Reader default: Open any PDF file -> Tap "Open with" -> Select Pepper Reader -> Tap "Always".',
                            ),
                            backgroundColor: AppColors.pepperRed,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.pepperRed.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.pepperRedSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 18,
                              color: AppColors.pepperRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as Default PDF Viewer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap to manage app defaults or choose "Always" when opening PDFs',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Recently Opened',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pepperRedSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${recents.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pepperRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent PDFs List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = recents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecentPdfCard(
                          pdf: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PdfReaderScreen(pdf: item),
                              ),
                            );
                          },
                          onRemove: () {
                            controller.removeRecentPdf(item.id);
                          },
                        ),
                      );
                    },
                    childCount: recents.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }
}

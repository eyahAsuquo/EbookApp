import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/library_controller.dart';
import 'package:ebook_app/controllers/reader_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/views/dictionary/bookmarks_screen.dart';
import 'package:ebook_app/views/dictionary/dictionary_search_screen.dart';
import 'package:ebook_app/views/library/widgets/book_card.dart';
import 'package:ebook_app/views/reader/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryController>().loadBooks();
    });
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
                Icons.menu_book_rounded,
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
      body: Consumer<LibraryController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pepperRed),
            );
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadBooks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final books = controller.books;

          return CustomScrollView(
            slivers: [
              // Hero Banner
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
                                  '100% OFFLINE READY',
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
                                'Tap Any Word to Define',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Read your ebooks with zero distraction and instant dictionary popups.',
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Text(
                    'Bookshelf',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              // Books List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          book: book,
                          onTap: () {
                            context.read<ReaderController>().openBook(book);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ReaderScreen()),
                            );
                          },
                        ),
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


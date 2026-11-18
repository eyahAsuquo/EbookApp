import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/dictionary_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/views/common_widgets/word_badge.dart';
import 'package:ebook_app/views/dictionary/bookmarks_screen.dart';
import 'package:ebook_app/views/dictionary/dictionary_bottom_sheet.dart';

class DictionarySearchScreen extends StatefulWidget {
  const DictionarySearchScreen({super.key});

  @override
  State<DictionarySearchScreen> createState() => _DictionarySearchScreenState();
}

class _DictionarySearchScreenState extends State<DictionarySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictionaryController>().search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Dictionary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded, color: AppColors.pepperRed),
            tooltip: 'Saved Vocabulary',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search offline vocabulary...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.pepperRed),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DictionaryController>().search('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.pepperRed, width: 1.8),
                ),
              ),
              onChanged: (val) {
                setState(() {});
                context.read<DictionaryController>().search(val);
              },
            ),
          ),

          // Search Results
          Expanded(
            child: Consumer<DictionaryController>(
              builder: (context, controller, child) {
                if (controller.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.pepperRed),
                  );
                }

                final results = controller.searchResults;

                if (results.isEmpty && controller.currentQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No matches found for "${controller.currentQuery}"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (results.isEmpty && controller.currentQuery.isEmpty) {
                  return Center(
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
                            Icons.menu_book_rounded,
                            size: 32,
                            color: AppColors.pepperRed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Type a word to search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Instant offline definitions, phonetics, and examples.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: results.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Row(
                        children: [
                          Text(
                            item.word,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          WordBadge(text: item.partOfSpeech),
                          const Spacer(),
                          if (item.isBookmarked)
                            const Icon(Icons.bookmark_rounded, size: 18, color: AppColors.gold),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.definition,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      onTap: () {
                        DictionaryBottomSheet.show(context, item);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


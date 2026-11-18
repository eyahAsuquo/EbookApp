import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/dictionary_controller.dart';
import 'package:ebook_app/controllers/library_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/models/recent_pdf.dart';
import 'package:ebook_app/views/dictionary/bookmarks_screen.dart';
import 'package:ebook_app/views/dictionary/dictionary_bottom_sheet.dart';
import 'package:ebook_app/views/dictionary/dictionary_search_screen.dart';

class PdfReaderScreen extends StatefulWidget {
  final RecentPdf pdf;

  const PdfReaderScreen({
    super.key,
    required this.pdf,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late final PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pdf.lastReadPage;
    _totalPages = widget.pdf.totalPages > 0 ? widget.pdf.totalPages : 1;
    _pdfController = PdfViewerController();
  }

  void _onPageChanged(int? page) {
    if (page != null && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      context.read<LibraryController>().updatePdfProgress(
            widget.pdf.id,
            page,
            _totalPages,
          );
    }
  }

  void _handleDefineWord(String rawText) async {
    final cleanWord = rawText.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
    if (cleanWord.isEmpty) return;

    final dictController = context.read<DictionaryController>();
    final definition = await dictController.lookupWord(cleanWord);

    if (definition != null && mounted) {
      DictionaryBottomSheet.show(context, definition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.pdf.filePath);

    if (!file.existsSync()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.pdf.fileName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_rounded, size: 64, color: AppColors.pepperRed),
                const SizedBox(height: 16),
                const Text(
                  'File Not Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The PDF at "${widget.pdf.filePath}" may have been moved, renamed, or deleted.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Library'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F5),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.pdf.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Page $_currentPage of $_totalPages',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      body: Stack(
        children: [
          // Native PDF viewer with selectable text layer
          PdfViewer.file(
            widget.pdf.filePath,
            controller: _pdfController,
            initialPageNumber: widget.pdf.lastReadPage > 0 ? widget.pdf.lastReadPage : 1,
            params: PdfViewerParams(
              backgroundColor: const Color(0xFFE8E8EC),
              onViewerReady: (document, controller) {
                setState(() {
                  _totalPages = document.pages.length;
                  _isReady = true;
                });
                context.read<LibraryController>().updatePdfProgress(
                      widget.pdf.id,
                      _currentPage,
                      document.pages.length,
                    );
              },
              onPageChanged: _onPageChanged,
              customizeContextMenuItems: (params, items) {
                // Add Pepper Red "Define" action at top of text selection menu
                items.insert(
                  0,
                  ContextMenuButtonItem(
                    label: 'Define',
                    onPressed: () async {
                      final selected = await params.textSelectionDelegate.getSelectedText();
                      params.dismissContextMenu();
                      if (selected.trim().isNotEmpty) {
                        _handleDefineWord(selected);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom floating helper tip
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isReady ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.pepperRedSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: AppColors.pepperRed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Highlight or tap any word to define',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous Page',
                      onPressed: _currentPage > 1
                          ? () => _pdfController.goToPage(pageNumber: _currentPage - 1)
                          : null,
                    ),
                    Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pepperRed,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next Page',
                      onPressed: _currentPage < _totalPages
                          ? () => _pdfController.goToPage(pageNumber: _currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

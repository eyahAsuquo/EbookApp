import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isReadingMode = false;
  bool _showReadingModeMenus = false;
  bool _hasSelectedText = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pdf.lastReadPage;
    _totalPages = widget.pdf.totalPages > 0 ? widget.pdf.totalPages : 1;
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    if (_isReadingMode && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
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

  void _enterReadingMode() {
    setState(() {
      _isReadingMode = true;
      _showReadingModeMenus = false;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitReadingMode() {
    setState(() {
      _isReadingMode = false;
      _showReadingModeMenus = false;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      backgroundColor: _isReadingMode ? Colors.black : const Color(0xFFF3F3F5),
      appBar: _isReadingMode
          ? null
          : AppBar(
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
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Reading Mode',
                  onPressed: _enterReadingMode,
                ),
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
          // PDF Viewer
          PdfViewer.file(
            widget.pdf.filePath,
            controller: _pdfController,
            initialPageNumber: widget.pdf.lastReadPage > 0 ? widget.pdf.lastReadPage : 1,
            params: PdfViewerParams(
              backgroundColor: _isReadingMode ? Colors.black : const Color(0xFFE8E8EC),
              layoutStrategy: _isReadingMode
                  ? const SequentialPagesLayout(
                      fitMode: PdfFitMode.fill,
                      margin: 0.0,
                      spacing: 0.0,
                    )
                  : const SequentialPagesLayout(
                      fitMode: PdfFitMode.fit,
                      margin: 8.0,
                      spacing: 8.0,
                    ),
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
              textSelectionParams: PdfTextSelectionParams(
                onTextSelectionChange: (textSelection) async {
                  _hasSelectedText = textSelection.hasSelectedText;
                  if (textSelection.hasSelectedText) {
                    final selected = await textSelection.getSelectedText();
                    final clean = selected.trim();
                    if (clean.isNotEmpty) {
                      _handleDefineWord(clean);
                    }
                  }
                },
              ),
              onGeneralTap: (context, controller, details) {
                final hasSelection = _hasSelectedText ||
                    (_isReady &&
                        _pdfController.textSelectionDelegate.hasSelectedText);

                if (!_isReadingMode) {
                  if (hasSelection) {
                    _hasSelectedText = false;
                    _pdfController.textSelectionDelegate.clearTextSelection();
                    return true;
                  } else {
                    if (details.type == PdfViewerGeneralTapType.tap) {
                      _enterReadingMode();
                      return true;
                    }
                  }
                } else {
                  if (hasSelection) {
                    if (details.type == PdfViewerGeneralTapType.doubleTap) {
                      _hasSelectedText = false;
                      _pdfController.textSelectionDelegate.clearTextSelection();
                      _exitReadingMode();
                      return true;
                    } else if (details.type == PdfViewerGeneralTapType.tap) {
                      _hasSelectedText = false;
                      _pdfController.textSelectionDelegate.clearTextSelection();
                      return true;
                    }
                  } else {
                    if (details.type == PdfViewerGeneralTapType.doubleTap) {
                      _exitReadingMode();
                      return true;
                    } else if (details.type == PdfViewerGeneralTapType.tap) {
                      setState(() {
                        _showReadingModeMenus = !_showReadingModeMenus;
                      });
                      return true;
                    }
                  }
                }
                return false;
              },
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

          // Normal Mode: Bottom floating helper tip & pagination
          if (!_isReadingMode)
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
                          'Tap screen for Reading Mode',
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

          // Reading Mode: Overlays shown when tapped once
          if (_isReadingMode && _showReadingModeMenus) ...[
            // Top Floating Header Overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      tooltip: 'Back',
                      onPressed: () {
                        _exitReadingMode();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.pdf.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Reading Mode (Double-tap to exit)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      tooltip: 'Search Dictionary',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DictionarySearchScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmarks_rounded, color: AppColors.gold, size: 20),
                      tooltip: 'Saved Vocabulary',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 22),
                      tooltip: 'Exit Reading Mode',
                      onPressed: _exitReadingMode,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Floating Pagination Overlay
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                      tooltip: 'Previous Page',
                      onPressed: _currentPage > 1
                          ? () => _pdfController.goToPage(pageNumber: _currentPage - 1)
                          : null,
                    ),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      tooltip: 'Next Page',
                      onPressed: _currentPage < _totalPages
                          ? () => _pdfController.goToPage(pageNumber: _currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

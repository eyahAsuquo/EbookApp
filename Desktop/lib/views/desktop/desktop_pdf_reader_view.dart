import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/controllers/library_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_dictionary_panel.dart';

class DesktopPdfReaderView extends StatefulWidget {
  final RecentPdf pdf;
  final VoidCallback onBack;

  const DesktopPdfReaderView({
    super.key,
    required this.pdf,
    required this.onBack,
  });

  @override
  State<DesktopPdfReaderView> createState() => _DesktopPdfReaderViewState();
}

class _DesktopPdfReaderViewState extends State<DesktopPdfReaderView> {
  late final PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isPanelOpen = true;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pdf.lastReadPage > 0 ? widget.pdf.lastReadPage : 1;
    _totalPages = widget.pdf.totalPages > 0 ? widget.pdf.totalPages : 1;
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
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

  void _defineWord(String rawText) async {
    final cleanWord = rawText.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
    if (cleanWord.isEmpty) return;

    if (!_isPanelOpen) {
      setState(() {
        _isPanelOpen = true;
      });
    }

    await context.read<DictionaryController>().lookupWord(cleanWord);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.pageDown) {
        if (_currentPage < _totalPages) {
          _pdfController.goToPage(pageNumber: _currentPage + 1);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        if (_currentPage > 1) {
          _pdfController.goToPage(pageNumber: _currentPage - 1);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isPanelOpen) {
          setState(() {
            _isPanelOpen = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.pdf.filePath);

    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_rounded, size: 64, color: AppColors.pepperRed),
            const SizedBox(height: 16),
            const Text(
              'PDF File Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('The file at "${widget.pdf.filePath}" does not exist.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onBack,
              child: const Text('Back to Library'),
            ),
          ],
        ),
      );
    }

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Desktop Toolbar Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Back to Library',
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.pdf.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Page Navigation Controls
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Page (Left Arrow)',
                  onPressed: _currentPage > 1
                      ? () => _pdfController.goToPage(pageNumber: _currentPage - 1)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pepperRed,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Page (Right Arrow)',
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfController.goToPage(pageNumber: _currentPage + 1)
                      : null,
                ),

                const SizedBox(width: 12),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                const SizedBox(width: 12),

                // Toggle Dictionary Panel Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isPanelOpen ? AppColors.pepperRed : AppColors.textSecondary,
                    side: BorderSide(
                      color: _isPanelOpen ? AppColors.pepperRed : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: Icon(
                    _isPanelOpen ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                    size: 16,
                  ),
                  label: Text(_isPanelOpen ? 'Hide Inspector' : 'Show Inspector'),
                  onPressed: () {
                    setState(() {
                      _isPanelOpen = !_isPanelOpen;
                    });
                  },
                ),
              ],
            ),
          ),

          // Main Canvas: Dual-Pane (PDF Viewer + Dictionary Inspector)
          Expanded(
            child: Row(
              children: [
                // PDF Viewer
                Expanded(
                  child: PdfViewer.file(
                    widget.pdf.filePath,
                    controller: _pdfController,
                    initialPageNumber: _currentPage,
                    params: PdfViewerParams(
                      backgroundColor: const Color(0xFFE4E4E8),
                      onViewerReady: (doc, controller) {
                        setState(() {
                          _totalPages = doc.pages.length;
                        });
                        context.read<LibraryController>().updatePdfProgress(
                              widget.pdf.id,
                              _currentPage,
                              doc.pages.length,
                            );
                      },
                      onPageChanged: _onPageChanged,
                      customizeContextMenuItems: (params, items) {
                        items.insert(
                          0,
                          ContextMenuButtonItem(
                            label: 'Define in Inspector',
                            onPressed: () async {
                              final text = await params.textSelectionDelegate.getSelectedText();
                              params.dismissContextMenu();
                              if (text.trim().isNotEmpty) {
                                _defineWord(text);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Right-side Dictionary Inspector Panel
                if (_isPanelOpen)
                  DesktopDictionaryPanel(
                    onClose: () {
                      setState(() {
                        _isPanelOpen = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

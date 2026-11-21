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
  final bool isReadingMode;
  final ValueChanged<bool> onReadingModeChanged;
  final ValueChanged<RecentPdf>? onOpenPdf;

  const DesktopPdfReaderView({
    super.key,
    required this.pdf,
    required this.onBack,
    required this.isReadingMode,
    required this.onReadingModeChanged,
    this.onOpenPdf,
  });

  @override
  State<DesktopPdfReaderView> createState() => _DesktopPdfReaderViewState();
}

class _DesktopPdfReaderViewState extends State<DesktopPdfReaderView> {
  late final PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isReady = false;
  bool _isPanelOpen = true;
  bool _showReadingModeMenus = false;
  bool _isReadingModeInspectorOpen = false;
  bool _hasSelectedText = false;
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

    if (!widget.isReadingMode) {
      if (!_isPanelOpen) {
        setState(() {
          _isPanelOpen = true;
        });
      }
    } else {
      if (!_isReadingModeInspectorOpen) {
        setState(() {
          _isReadingModeInspectorOpen = true;
        });
      }
    }

    await context.read<DictionaryController>().lookupWord(cleanWord);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyO) {
        context.read<LibraryController>().pickAndOpenPdf().then((picked) {
          if (picked != null && mounted) {
            widget.onOpenPdf?.call(picked);
          }
        });
        return;
      }

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
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.f11) {
        if (widget.isReadingMode) {
          if (_hasSelectedText || _isReadingModeInspectorOpen) {
            _hasSelectedText = false;
            _pdfController.textSelectionDelegate.clearTextSelection();
            setState(() {
              _isReadingModeInspectorOpen = false;
            });
          } else {
            widget.onReadingModeChanged(false);
          }
        } else if (_isPanelOpen) {
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
      child: Stack(
        children: [
          Column(
            children: [
              // Normal Mode Desktop Toolbar Header
              if (!widget.isReadingMode)
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.pepperRed.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
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

                      // Enter Reading Mode Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.pepperRed,
                          side: const BorderSide(color: AppColors.pepperRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.fullscreen_rounded, size: 16),
                        label: const Text('Reading Mode'),
                        onPressed: () => widget.onReadingModeChanged(true),
                      ),

                      const SizedBox(width: 8),

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

              // Main Canvas: Full Window in Reading Mode, Dual-Pane in Normal Mode
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
                          backgroundColor: widget.isReadingMode ? Colors.black : const Color(0xFFE4E4E8),
                          layoutStrategy: widget.isReadingMode
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
                          onViewerReady: (doc, controller) {
                            setState(() {
                              _totalPages = doc.pages.length;
                              _isReady = true;
                            });
                            context.read<LibraryController>().updatePdfProgress(
                                  widget.pdf.id,
                                  _currentPage,
                                  doc.pages.length,
                                );
                          },
                          onPageChanged: _onPageChanged,
                          textSelectionParams: PdfTextSelectionParams(
                            onTextSelectionChange: (textSelection) async {
                              final hasText = textSelection.hasSelectedText;
                              _hasSelectedText = hasText;
                              if (hasText) {
                                final selected =
                                    await textSelection.getSelectedText();
                                final clean = selected.trim();
                                if (clean.isNotEmpty) {
                                  _defineWord(clean);
                                }
                              } else {
                                if (widget.isReadingMode &&
                                    _isReadingModeInspectorOpen) {
                                  setState(() {
                                    _isReadingModeInspectorOpen = false;
                                  });
                                }
                              }
                            },
                          ),
                          onGeneralTap: (context, controller, details) {
                            final hasSelection = _hasSelectedText ||
                                (_isReady &&
                                    _pdfController
                                        .textSelectionDelegate.hasSelectedText);

                            if (!widget.isReadingMode) {
                              if (hasSelection) {
                                _hasSelectedText = false;
                                _pdfController.textSelectionDelegate
                                    .clearTextSelection();
                                return true;
                              } else {
                                if (details.type ==
                                    PdfViewerGeneralTapType.tap) {
                                  widget.onReadingModeChanged(true);
                                  return true;
                                }
                              }
                            } else {
                              if (hasSelection) {
                                if (details.type ==
                                    PdfViewerGeneralTapType.doubleTap) {
                                  _hasSelectedText = false;
                                  _pdfController.textSelectionDelegate
                                    .clearTextSelection();
                                  setState(() {
                                    _isReadingModeInspectorOpen = false;
                                  });
                                  widget.onReadingModeChanged(false);
                                  return true;
                                } else if (details.type ==
                                    PdfViewerGeneralTapType.tap) {
                                  _hasSelectedText = false;
                                  _pdfController.textSelectionDelegate
                                    .clearTextSelection();
                                  setState(() {
                                    _isReadingModeInspectorOpen = false;
                                  });
                                  return true;
                                }
                              } else {
                                if (details.type ==
                                    PdfViewerGeneralTapType.doubleTap) {
                                  widget.onReadingModeChanged(false);
                                  return true;
                                } else if (details.type ==
                                    PdfViewerGeneralTapType.tap) {
                                  setState(() {
                                    _showReadingModeMenus =
                                        !_showReadingModeMenus;
                                  });
                                  return true;
                                }
                              }
                            }
                            return false;
                          },
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

                    // Right-side Dictionary Inspector Panel (Normal Mode)
                    if (!widget.isReadingMode && _isPanelOpen)
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

          // Reading Mode: Overlays shown when tapped once
          if (widget.isReadingMode && _showReadingModeMenus) ...[
            // Top Floating Header Overlay
            Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      tooltip: 'Back to Library',
                      onPressed: () {
                        widget.onReadingModeChanged(false);
                        widget.onBack();
                      },
                    ),
                    const SizedBox(width: 8),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Reading Mode (Double-click or Esc to return to normal)',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.fullscreen_exit_rounded, size: 18),
                      label: const Text('Exit Reading Mode'),
                      onPressed: () => widget.onReadingModeChanged(false),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Floating Pagination Overlay
            Positioned(
              bottom: 20,
              left: 48,
              right: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
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
                        fontWeight: FontWeight.bold,
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

          // Reading Mode: Sliding Dictionary Inspector Pane from right
          if (widget.isReadingMode)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              right: _isReadingModeInspectorOpen ? 0 : -370,
              width: 360,
              child: Material(
                elevation: 16,
                color: Colors.white,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.pepperRed,
                        width: 2,
                      ),
                    ),
                  ),
                  child: DesktopDictionaryPanel(
                    onClose: () {
                      setState(() {
                        _isReadingModeInspectorOpen = false;
                      });
                      _hasSelectedText = false;
                      _pdfController.textSelectionDelegate.clearTextSelection();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

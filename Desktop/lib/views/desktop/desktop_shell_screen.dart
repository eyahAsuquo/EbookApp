import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/library_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/services/file_association_service.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_library_view.dart';
import 'package:ebook_app_desktop/views/desktop/desktop_pdf_reader_view.dart';
import 'package:ebook_app_desktop/views/dictionary/bookmarks_screen.dart';
import 'package:ebook_app_desktop/views/dictionary/dictionary_search_screen.dart';
import 'package:ebook_app_desktop/views/dictionary/vocabulary_study_screen.dart';

class DesktopShellScreen extends StatefulWidget {
  final String? initialFilePath;

  const DesktopShellScreen({
    super.key,
    this.initialFilePath,
  });

  @override
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  int _selectedIndex = 0;
  RecentPdf? _activePdf;
  bool _isDefaultViewer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final libraryController = context.read<LibraryController>();
      await libraryController.loadRecentPdfs();

      // Open initial PDF if passed via command line / file association
      if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
        final pdf = await libraryController.openPdfFromPath(widget.initialFilePath!);
        if (pdf != null && mounted) {
          _openPdf(pdf);
        }
      }

      _checkDefaultViewerStatus();
    });
  }

  Future<void> _checkDefaultViewerStatus() async {
    final isDefault = await FileAssociationService.instance.isPdfAssociated();
    if (mounted) {
      setState(() {
        _isDefaultViewer = isDefault;
      });
    }
  }

  Future<void> _registerAsDefault() async {
    final success = await FileAssociationService.instance.registerPdfAssociation();
    if (mounted) {
      setState(() {
        _isDefaultViewer = success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
              ? 'Pepper Reader is now set as your default PDF viewer!'
              : 'Could not register file association automatically. You can also right-click any PDF -> Open with -> Choose Pepper Reader.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.textPrimary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _openPdf(RecentPdf pdf) {
    setState(() {
      _activePdf = pdf;
      _selectedIndex = 1; // Switch to Reader tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Desktop Sidebar
          Material(
            color: Colors.white,
            child: Container(
              width: 270,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Branding Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pepperRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pepper Reader',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Desktop Edition',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Primary "Open PDF" Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pepperRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Open PDF (Ctrl+O)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () async {
                        final pdf = await context.read<LibraryController>().pickAndOpenPdf();
                        if (pdf != null) {
                          _openPdf(pdf);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    children: [
                      _buildNavItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Recent Documents',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.menu_book_rounded,
                        label: _activePdf != null
                            ? 'Reader (${_activePdf!.fileName})'
                            : 'Reader (No PDF)',
                        index: 1,
                        enabled: _activePdf != null,
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'VOCABULARY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      _buildNavItem(
                        icon: Icons.bookmark_rounded,
                        label: 'Saved Words',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.style_rounded,
                        label: 'Flashcards Practice',
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: Icons.search_rounded,
                        label: 'Search Dictionary',
                        index: 4,
                      ),
                    ],
                  ),
                ),

                // Default PDF App Association Status Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  decoration: BoxDecoration(
                    color: _isDefaultViewer ? AppColors.success.withValues(alpha: 0.08) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDefaultViewer ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDefaultViewer ? Icons.check_circle_rounded : Icons.picture_as_pdf_outlined,
                        size: 16,
                        color: _isDefaultViewer ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isDefaultViewer ? 'Default PDF App' : 'Set Default App',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isDefaultViewer ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!_isDefaultViewer)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: _registerAsDefault,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.pepperRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Set',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Offline Database Status Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.pepperRed),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '102,000+ Words',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '100% Offline SQLite',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

          // Main Screen Area
          Expanded(
            child: _buildSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool enabled = true,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        enabled: enabled,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: AppColors.pepperRedSoft,
        leading: Icon(
          icon,
          size: 18,
          color: isSelected
              ? AppColors.pepperRed
              : (enabled ? AppColors.textSecondary : AppColors.textMuted),
        ),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.pepperRed
                : (enabled ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ),
        onTap: enabled
            ? () {
                setState(() {
                  _selectedIndex = index;
                });
              }
            : null,
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return DesktopLibraryView(
          onOpenPdf: _openPdf,
        );
      case 1:
        if (_activePdf != null) {
          return DesktopPdfReaderView(
            pdf: _activePdf!,
            onBack: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          );
        }
        return DesktopLibraryView(onOpenPdf: _openPdf);
      case 2:
        return const BookmarksScreen();
      case 3:
        return const VocabularyStudyScreen();
      case 4:
        return const DictionarySearchScreen();
      default:
        return DesktopLibraryView(onOpenPdf: _openPdf);
    }
  }
}

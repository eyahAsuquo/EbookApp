import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/library_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/views/common_widgets/pepper_button.dart';
import 'package:ebook_app_desktop/views/library/widgets/recent_pdf_card.dart';

class DesktopLibraryView extends StatelessWidget {
  final void Function(RecentPdf pdf) onOpenPdf;

  const DesktopLibraryView({
    super.key,
    required this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.pepperRed),
          );
        }

        final recents = controller.recentPdfs;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                Container(
                  padding: const EdgeInsets.all(28),
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
                        color: AppColors.pepperRed.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Desktop PDF Reader',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Read documents with dual-pane dictionary inspector, keyboard shortcuts, and 102,000+ offline word definitions.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      PepperButton(
                        label: 'Open PDF Document',
                        icon: Icons.folder_open_rounded,
                        onPressed: () async {
                          final pdf = await controller.pickAndOpenPdf();
                          if (pdf != null) {
                            onOpenPdf(pdf);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section Header
                Row(
                  children: [
                    const Text(
                      'Recently Opened Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                const SizedBox(height: 16),

                // Content: Empty State or Grid
                Expanded(
                  child: recents.isEmpty
                      ? _buildEmptyState(context, controller)
                      : _buildRecentsGrid(recents, controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, LibraryController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.pepperRedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 36,
                color: AppColors.pepperRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No PDF Documents Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Open a PDF from your computer to start reading with the built-in dictionary.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            PepperButton(
              label: 'Choose PDF from Computer',
              icon: Icons.folder_open_rounded,
              onPressed: () async {
                final pdf = await controller.pickAndOpenPdf();
                if (pdf != null) {
                  onOpenPdf(pdf);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentsGrid(List<RecentPdf> recents, LibraryController controller) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 110,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recents.length,
      itemBuilder: (context, index) {
        final item = recents[index];
        return RecentPdfCard(
          pdf: item,
          onTap: () => onOpenPdf(item),
          onRemove: () => controller.removeRecentPdf(item.id),
        );
      },
    );
  }
}

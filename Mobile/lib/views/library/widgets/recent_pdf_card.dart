import 'package:flutter/material.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/models/recent_pdf.dart';

class RecentPdfCard extends StatelessWidget {
  final RecentPdf pdf;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const RecentPdfCard({
    super.key,
    required this.pdf,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // PDF Document Icon Badge
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.pepperRed,
                      AppColors.pepperRedDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pepperRed.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                    SizedBox(height: 2),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // PDF Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          pdf.formattedFileSize,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Text(
                          pdf.formattedLastOpened,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.pepperRedSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Page ${pdf.lastReadPage} of ${pdf.totalPages > 0 ? pdf.totalPages : 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pepperRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                tooltip: 'Remove from recents',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

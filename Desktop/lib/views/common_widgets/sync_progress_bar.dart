import 'package:flutter/material.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';

class SyncProgressBar extends StatelessWidget {
  final double progress;
  final String status;
  final bool isComplete;

  const SyncProgressBar({
    super.key,
    required this.progress,
    required this.status,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete ? AppColors.success : AppColors.pepperRedSoft,
                ),
                child: Icon(
                  isComplete ? Icons.check_rounded : Icons.offline_bolt_rounded,
                  size: 14,
                  color: isComplete ? Colors.white : AppColors.pepperRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isComplete ? 'Offline Engine Ready' : 'Setting up Offline Dictionary...',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? AppColors.success : AppColors.pepperRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.divider.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.success : AppColors.pepperRed,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


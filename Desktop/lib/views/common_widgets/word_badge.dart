import 'package:flutter/material.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';

class WordBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const WordBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.pepperRedSoft;
    final fg = textColor ?? AppColors.pepperRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toLowerCase(),
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

